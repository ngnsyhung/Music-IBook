using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Music_IBook_API.DTOs;
using Music_IBook_API.Services;

namespace Music_IBook_API.Controllers;

[ApiController]
[Route("api/lessons")]
public class LessonsController : BaseController
{
    private readonly ILessonService lessonService;

    public LessonsController(ILessonService lessonService)
    {
        this.lessonService = lessonService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var lessons = await lessonService.GetAllAsync();
        return Ok(lessons);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(long id)
    {
        var lesson = await lessonService.GetByIdAsync(id);
        return lesson == null ? NotFound() : Ok(lesson);
    }

    [Authorize(Roles = "Teacher")]
    [HttpPost]
    public async Task<IActionResult> Create(CreateLessonRequest request)
    {
        var lesson = await lessonService.CreateAsync(CurrentUserId, request);
        return Ok(lesson);
    }

    [Authorize(Roles = "Teacher")]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(long id, CreateLessonRequest request)
    {
        var lesson = await lessonService.UpdateAsync(id, request);
        return Ok(lesson);
    }

    [Authorize(Roles = "Teacher")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(long id)
    {
        await lessonService.DeleteAsync(id);
        return Ok(new { message = "Xóa bài học thành công" });
    }

    [Authorize(Roles = "Teacher")]
    [HttpPost("{lessonId}/notes")]
    public async Task<IActionResult> AddNote(
    long lessonId,
    AddLessonNoteRequest request)
    {
        var note = await lessonService.AddNoteAsync(lessonId, request);

        return Ok(new
        {
            note.Id,
            note.LessonId,
            note.Second,
            note.StartBeat,
            note.DurationBeat,
            note.Velocity,
            note.Staff,
            note.Voice,
            note.Note,
            note.Duration,
            note.Lyric,
            note.Chord
        });
    }

    [Authorize(Roles = "Teacher")]
    [HttpDelete("notes/{noteId}")]
    public async Task<IActionResult> DeleteNote(long noteId)
    {
        await lessonService.DeleteNoteAsync(noteId);
        return Ok(new { message = "Xóa nốt thành công" });
    }

    [Authorize(Roles = "Teacher")]
    [HttpPost("{lessonId}/audio")]
    public async Task<IActionResult> UploadAudio(long lessonId, IFormFile file)
    {
        var url = await lessonService.UploadAudioAsync(lessonId, file);
        return Ok(new { audioUrl = url });
    }

    [Authorize(Roles = "Teacher")]
    [HttpPut("{lessonId}/publish")]
    public async Task<IActionResult> Publish(long lessonId)
    {
        await lessonService.PublishAsync(lessonId);
        return Ok(new { message = "Đã xuất bản bài học" });
    }

    [Authorize(Roles = "Teacher")]
    [HttpPost("{lessonId}/content")]
    public async Task<IActionResult> SaveContent(
    long lessonId,
    SaveLessonContentRequest request)
    {
        await lessonService.SaveLessonContentAsync(lessonId, request);

        return Ok();
    }

    [Authorize(Roles = "Teacher")]
    [HttpDelete("{lessonId}/notes")]
    public async Task<IActionResult> DeleteAllNotes(long lessonId)
    {
        await lessonService.DeleteAllNotesAsync(lessonId);
        return Ok();
    }
}
