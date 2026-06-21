using Music_IBook_API.DTOs;
using Music_IBook_API.Models;

namespace Music_IBook_API.Services;

public interface IStudentService
{
    Task<StudentLessonProgress> SaveProgressAsync(long studentId, long lessonId, SaveProgressRequest request);
    Task<List<StudentLessonProgress>> GetProgressAsync(long studentId);
    Task<PracticeSession> SubmitPracticeAsync(long studentId, SubmitPracticeRequest request);
    Task<List<PracticeSession>> GetPracticeHistoryAsync(long studentId);
}