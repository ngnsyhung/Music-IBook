using Microsoft.EntityFrameworkCore;
using Music_IBook_API.DTOs;
using Music_IBook_API.Models;

namespace Music_IBook_API.Services;

public class StudentService : IStudentService
{
    private readonly MusicIBookDbContext db;

    public StudentService(MusicIBookDbContext db)
    {
        this.db = db;
    }

    public async Task<StudentLessonProgress> SaveProgressAsync(
        long studentId,
        long lessonId,
        SaveProgressRequest request)
    {
        var progress = await db.StudentLessonProgresses
            .FirstOrDefaultAsync(x => x.StudentId == studentId && x.LessonId == lessonId);

        if (progress == null)
        {
            progress = new StudentLessonProgress
            {
                StudentId = studentId,
                LessonId = lessonId
            };

            db.StudentLessonProgresses.Add(progress);
        }

        progress.LastPositionSecond = request.LastPositionSecond;
        progress.CompletedNoteCount = request.CompletedNoteCount;
        progress.BestScore = Math.Max(progress.BestScore, request.BestScore);
        progress.IsCompleted = request.IsCompleted;
        progress.TotalAttempts += 1;
        progress.LastStudiedAtUtc = DateTime.UtcNow;

        await db.SaveChangesAsync();
        return progress;
    }

    public async Task<List<StudentLessonProgress>> GetProgressAsync(long studentId)
    {
        return await db.StudentLessonProgresses
            .Include(x => x.Lesson)
            .Where(x => x.StudentId == studentId)
            .OrderByDescending(x => x.LastStudiedAtUtc)
            .ToListAsync();
    }

    public async Task<PracticeSession> SubmitPracticeAsync(
        long studentId,
        SubmitPracticeRequest request)
    {
        var lessonNotes = await db.LessonNotes
            .Where(x => x.LessonId == request.LessonId)
            .ToListAsync();

        var session = new PracticeSession
        {
            StudentId = studentId,
            LessonId = request.LessonId,
            IsExam = request.IsExam,
            DurationSeconds = request.DurationSeconds,
            StartedAtUtc = DateTime.UtcNow,
            FinishedAtUtc = DateTime.UtcNow,
            CreatedAtUtc = DateTime.UtcNow
        };

        db.PracticeSessions.Add(session);
        await db.SaveChangesAsync();

        int correct = 0;
        int wrong = 0;

        foreach (var attempt in request.Attempts)
        {
            var expected = lessonNotes.FirstOrDefault(x => x.Id == attempt.LessonNoteId);
            if (expected == null) continue;

            var offsetMs = Math.Abs((attempt.PlayedAtSecond - expected.Second) * 1000);

            var correctPitch = attempt.PlayedNote == expected.Note;
            var correctTiming = request.IsExam ? offsetMs <= 300 : true; // In practice mode, timing might not be strict or just always correct if they hit it? Let's use same logic but maybe exam is stricter. User said Exam <= 0.3s. For practice, we will use <= 300 as well for correctTiming but we don't penalize score if they wait. Wait, in practice "1.5, 1.4... 0 thì phải đánh". That means they wait for 0. So let's keep offsetMs <= 300.
            var isCorrect = correctPitch && (request.IsExam ? correctTiming : true); // In practice mode they might take longer, but if they hit the right note it's correct? Let's say in practice mode, as long as it's the right note, it's correct? User said "Khi học sinh bấm phím: So sánh với lesson.notes[currentIndex], Nếu đúng: Tăng correct count". It doesn't mention timing strictly for practice, only for exam. So I will just require correctPitch for Practice, and both for Exam.
            
            // Revert the logic comment block and simplify:
            isCorrect = request.IsExam ? (correctPitch && correctTiming) : correctPitch;

            if (isCorrect) correct++;
            else wrong++;

            db.StudentNoteAttempts.Add(new StudentNoteAttempt
            {
                PracticeSessionId = session.Id,
                LessonNoteId = expected.Id,
                ExpectedNote = expected.Note,
                PlayedNote = attempt.PlayedNote,
                ExpectedAtSecond = expected.Second,
                PlayedAtSecond = attempt.PlayedAtSecond,
                TimingErrorMs = offsetMs,
                IsCorrectPitch = correctPitch,
                IsCorrectTiming = correctTiming,
                IsCorrect = isCorrect,
                CreatedAtUtc = DateTime.UtcNow
            });
        }

        var total = correct + wrong;

        session.CorrectCount = correct;
        session.WrongCount = wrong;
        session.Accuracy = total == 0 ? 0 : Math.Round((double)correct / total * 100, 2);
        session.Score = correct * 10;

        await db.SaveChangesAsync();

        return session;
    }

    public async Task<List<PracticeSession>> GetPracticeHistoryAsync(long studentId)
    {
        return await db.PracticeSessions
            .Include(x => x.Lesson)
            .Include(x => x.NoteAttempts)
            .Where(x => x.StudentId == studentId)
            .OrderByDescending(x => x.StartedAtUtc)
            .ToListAsync();
    }
}