using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Moq;
using Music_IBook_API.DTOs;
using Music_IBook_API.Models;
using Music_IBook_API.Services;
using Xunit;

namespace Music_IBook_API.Tests.Services;

public class LessonServiceTests
{
    private MusicIBookDbContext GetDbContext()
    {
        var options = new DbContextOptionsBuilder<MusicIBookDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new MusicIBookDbContext(options);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesLesson()
    {
        // Arrange
        using var db = GetDbContext();
        var mockEnv = new Mock<IWebHostEnvironment>();
        var service = new LessonService(db, mockEnv.Object);

        var request = new CreateLessonRequest
        {
            Title = "Fur Elise",
            Composer = "Beethoven",
            Clef = "G",
            KeySignature = "C",
            TimeSignature = "3/8",
            TimeSignatureMap = "[]",
            TempoMap = "[]",
            Tempo = 80
        };

        // Act
        var result = await service.CreateAsync(teacherId: 1, request);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Fur Elise", result.Title);
        Assert.Equal(1, result.TeacherId);
        Assert.False(result.IsPublished); // Default is false

        var savedLesson = await db.Lessons.FirstOrDefaultAsync();
        Assert.NotNull(savedLesson);
        Assert.Equal("Beethoven", savedLesson.Composer);
    }

    [Fact]
    public async Task UpdateAsync_ExistingLesson_UpdatesDetails()
    {
        // Arrange
        using var db = GetDbContext();
        db.Lessons.Add(new MusicLesson { Id = 1, TeacherId = 1, Title = "Old Title", Composer = "Old Composer", Clef = "G", KeySignature = "C", TimeSignature = "4/4", TimeSignatureMap = "[]", TempoMap = "[]", Tempo = 100, CreatedAtUtc = DateTime.UtcNow });
        await db.SaveChangesAsync();

        var mockEnv = new Mock<IWebHostEnvironment>();
        var service = new LessonService(db, mockEnv.Object);

        var request = new CreateLessonRequest
        {
            Title = "New Title",
            Composer = "New Composer",
            Clef = "G",
            KeySignature = "C",
            TimeSignature = "3/4",
            TimeSignatureMap = "[]",
            TempoMap = "[]",
            Tempo = 120
        };

        // Act
        var result = await service.UpdateAsync(1, request);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("New Title", result.Title);
        Assert.Equal(120, result.Tempo);

        var savedLesson = await db.Lessons.FirstOrDefaultAsync(x => x.Id == 1);
        Assert.NotNull(savedLesson);
        Assert.Equal("New Composer", savedLesson.Composer);
    }

    [Fact]
    public async Task DeleteAsync_ExistingLesson_RemovesLessonAndCascadeEntities()
    {
        // Arrange
        using var db = GetDbContext();
        db.Lessons.Add(new MusicLesson { Id = 1, TeacherId = 1, Title = "Title", Composer = "C", Clef = "G", KeySignature = "C", TimeSignature = "4/4", TimeSignatureMap = "[]", TempoMap = "[]", Tempo = 100, CreatedAtUtc = DateTime.UtcNow });
        db.LessonNotes.Add(new LessonNote { Id = 1, LessonId = 1, Second = 1.0, StartBeat = 1, DurationBeat = 1, Velocity = 100, Track = 1, TrackName = "Piano", Staff = 1, Voice = 1, Note = "C4", Duration = "quarter", Lyric = "", Chord = "", Fingering = "" });
        await db.SaveChangesAsync();

        var mockEnv = new Mock<IWebHostEnvironment>();
        var service = new LessonService(db, mockEnv.Object);

        // Act
        await service.DeleteAsync(1);

        // Assert
        Assert.Empty(await db.Lessons.ToListAsync());
        Assert.Empty(await db.LessonNotes.ToListAsync());
    }
}
