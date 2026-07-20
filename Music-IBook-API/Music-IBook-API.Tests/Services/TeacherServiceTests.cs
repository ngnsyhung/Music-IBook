using Microsoft.EntityFrameworkCore;
using Music_IBook_API.DTOs;
using Music_IBook_API.Models;
using Music_IBook_API.Services;
using Xunit;

namespace Music_IBook_API.Tests.Services;

public class TeacherServiceTests
{
    private MusicIBookDbContext GetDbContext()
    {
        var options = new DbContextOptionsBuilder<MusicIBookDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new MusicIBookDbContext(options);
    }

    [Fact]
    public async Task AssignSupplementaryWorkAsync_ValidRequest_CreatesAssignment()
    {
        // Arrange
        using var db = GetDbContext();
        
        db.Users.Add(new AppUser { Id = 10, FullName = "Student 1", Email = "student1@test.com", Role = "Student", PasswordHash = "", AuthProvider = "Local" });
        db.Lessons.Add(new MusicLesson { Id = 5, TeacherId = 1, Title = "Test Lesson", Composer = "Test", Clef = "G", KeySignature = "C", TimeSignature = "4/4", TimeSignatureMap = "[]", TempoMap = "[]", Tempo = 100, CreatedAtUtc = DateTime.UtcNow, IsPublished = true });
        await db.SaveChangesAsync();

        var service = new TeacherService(db);
        var request = new CreateStudentAssignmentRequest
        {
            StudentId = 10,
            LessonId = 5,
            Message = "Practice more",
            DueAtUtc = DateTime.UtcNow.AddDays(1)
        };

        // Act
        var result = await service.CreateStudentAssignmentAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(10, result.StudentId);
        Assert.Equal(5, result.LessonId);
        Assert.Equal("Practice more", result.Message);
        
        var assignment = await db.StudentAssignments.FirstOrDefaultAsync();
        Assert.NotNull(assignment);
        Assert.False(assignment.IsCompleted);
    }
}
