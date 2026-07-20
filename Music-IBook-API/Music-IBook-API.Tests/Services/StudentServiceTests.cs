using Microsoft.EntityFrameworkCore;
using Music_IBook_API.DTOs;
using Music_IBook_API.Models;
using Music_IBook_API.Services;
using Xunit;

namespace Music_IBook_API.Tests.Services;

public class StudentServiceTests
{
    private MusicIBookDbContext GetDbContext()
    {
        var options = new DbContextOptionsBuilder<MusicIBookDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new MusicIBookDbContext(options);
    }

    [Fact]
    public async Task SaveProgressAsync_NewProgress_CreatesProgress()
    {
        // Arrange
        using var db = GetDbContext();
        var service = new StudentService(db);
        
        var request = new SaveProgressRequest
        {
            LastPositionSecond = 15.5,
            CompletedNoteCount = 10,
            BestScore = 80,
            IsCompleted = false
        };

        // Act
        var progress = await service.SaveProgressAsync(studentId: 1, lessonId: 1, request);

        // Assert
        Assert.NotNull(progress);
        Assert.Equal(15.5, progress.LastPositionSecond);
        Assert.Equal(10, progress.CompletedNoteCount);
        Assert.Equal(80, progress.BestScore);
        Assert.Equal(1, progress.TotalAttempts); // Total attempts increments by 1

        var savedProgress = await db.StudentLessonProgresses.FirstOrDefaultAsync();
        Assert.NotNull(savedProgress);
        Assert.Equal(1, savedProgress.StudentId);
        Assert.Equal(1, savedProgress.LessonId);
    }

    [Fact]
    public async Task SaveProgressAsync_ExistingProgress_UpdatesProgressAndKeepsBestScore()
    {
        // Arrange
        using var db = GetDbContext();
        db.StudentLessonProgresses.Add(new StudentLessonProgress
        {
            StudentId = 1,
            LessonId = 1,
            BestScore = 90,
            TotalAttempts = 2
        });
        await db.SaveChangesAsync();

        var service = new StudentService(db);
        var request = new SaveProgressRequest
        {
            LastPositionSecond = 30,
            CompletedNoteCount = 50,
            BestScore = 85, // New score is lower than best
            IsCompleted = true
        };

        // Act
        var progress = await service.SaveProgressAsync(studentId: 1, lessonId: 1, request);

        // Assert
        Assert.NotNull(progress);
        Assert.Equal(30, progress.LastPositionSecond);
        Assert.Equal(90, progress.BestScore); // Should keep the old BestScore 90
        Assert.Equal(3, progress.TotalAttempts); // Incremented from 2 to 3
        Assert.True(progress.IsCompleted);
    }

    [Fact]
    public async Task SubmitPracticeAsync_CalculatesScoreCorrectly()
    {
        // Arrange
        using var db = GetDbContext();
        
        var lesson = new MusicLesson { Id = 1, TeacherId = 1, Title = "Test Lesson", Composer = "Test", Clef = "G", KeySignature = "C", TimeSignature = "4/4", TimeSignatureMap = "[]", TempoMap = "[]", Tempo = 60, CreatedAtUtc = DateTime.UtcNow, IsPublished = true };
        var note1 = new LessonNote { Id = 101, LessonId = 1, Second = 1.0, StartBeat = 1, DurationBeat = 1, Velocity = 100, Track = 1, TrackName = "Piano", Staff = 1, Voice = 1, Note = "C4", Duration = "quarter", Lyric = "", Chord = "", Fingering = "" };
        var note2 = new LessonNote { Id = 102, LessonId = 1, Second = 2.0, StartBeat = 2, DurationBeat = 1, Velocity = 100, Track = 1, TrackName = "Piano", Staff = 1, Voice = 1, Note = "D4", Duration = "quarter", Lyric = "", Chord = "", Fingering = "" };
        
        db.Lessons.Add(lesson);
        db.LessonNotes.AddRange(note1, note2);
        await db.SaveChangesAsync();

        var service = new StudentService(db);
        var request = new SubmitPracticeRequest
        {
            LessonId = 1,
            IsExam = false,
            DurationSeconds = 60,
            Attempts = new List<SubmitNoteAttemptRequest>
            {
                new SubmitNoteAttemptRequest { LessonNoteId = 101, PlayedNote = "C4", PlayedAtSecond = 1.05, TimingErrorMs = 50, JudgeResult = "PERFECT" }, // Right note, perfect timing
                new SubmitNoteAttemptRequest { LessonNoteId = 102, PlayedNote = "E4", PlayedAtSecond = 2.5, TimingErrorMs = 500, JudgeResult = "WRONG" } // Wrong note
            }
        };

        // Act
        var session = await service.SubmitPracticeAsync(studentId: 1, request);

        // Assert
        Assert.NotNull(session);
        Assert.Equal(1, session.StudentId);
        Assert.Equal(1, session.LessonId);
        Assert.Equal(1, session.CorrectCount); // Only first note correct
        Assert.Equal(1, session.WrongCount); // Second note wrong
        Assert.Equal(50, session.Accuracy); // 1 / 2 = 50%
        
        var attempts = await db.StudentNoteAttempts.Where(x => x.PracticeSessionId == session.Id).ToListAsync();
        Assert.Equal(2, attempts.Count);
    }
}
