using Music_IBook_API.DTOs;
using Music_IBook_API.Models;

namespace Music_IBook_API.Services;

public interface ILessonService
{
    Task<List<MusicLesson>> GetAllAsync();
    Task<MusicLesson?> GetByIdAsync(long id);
    Task<MusicLesson> CreateAsync(long teacherId, CreateLessonRequest request);
    Task<MusicLesson> UpdateAsync(long id, CreateLessonRequest request);
    Task DeleteAsync(long id);
    Task<LessonNote> AddNoteAsync(long lessonId, AddLessonNoteRequest request);
    Task DeleteNoteAsync(long noteId);
    Task<string> UploadAudioAsync(long lessonId, IFormFile file);
    Task PublishAsync(long lessonId);
    Task SaveLessonContentAsync(long lessonId, SaveLessonContentRequest request);
    Task DeleteAllNotesAsync(long lessonId);
}