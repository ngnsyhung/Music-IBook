using Microsoft.EntityFrameworkCore;
using Music_IBook_API.DTOs;
using Music_IBook_API.Models;

namespace Music_IBook_API.Services;

public class LessonService : ILessonService
{
    private readonly MusicIBookDbContext db;
    private readonly IWebHostEnvironment env;

    public LessonService(MusicIBookDbContext db, IWebHostEnvironment env)
    {
        this.db = db;
        this.env = env;
    }

    public async Task<List<MusicLesson>> GetAllAsync()
    {
        return await db.Lessons
            .Include(x => x.Notes.OrderBy(n => n.StartBeat).ThenBy(n => n.Note))
            .Where(x => x.IsPublished)
            .ToListAsync();
    }

    public async Task<MusicLesson?> GetByIdAsync(long id)
    {
        return await db.Lessons
            .Include(x => x.Notes.OrderBy(n => n.StartBeat).ThenBy(n => n.Note))
            .FirstOrDefaultAsync(x => x.Id == id);
    }

    public async Task<MusicLesson> CreateAsync(long teacherId, CreateLessonRequest request)
    {
        var lesson = new MusicLesson
        {
            TeacherId = teacherId,
            Title = request.Title,
            Composer = request.Composer,
            Clef = request.Clef,
            KeySignature = request.KeySignature,
            TimeSignature = request.TimeSignature,
            TimeSignatureMap = request.TimeSignatureMap,
            Tempo = request.Tempo,
            TheoryTitle = request.TheoryTitle,
            TheoryContent = request.TheoryContent,
            PracticeGuide = request.PracticeGuide,
            IsPublished = false
        };

        db.Lessons.Add(lesson);
        await db.SaveChangesAsync();

        return lesson;
    }

    public async Task<MusicLesson> UpdateAsync(long id, CreateLessonRequest request)
    {
        var lesson = await db.Lessons.FindAsync(id);
        if (lesson == null)
            throw new Exception("Không tìm thấy bài học");

        lesson.Title = request.Title;
        lesson.Composer = request.Composer;
        lesson.Clef = request.Clef;
        lesson.KeySignature = request.KeySignature;
        lesson.TimeSignature = request.TimeSignature;
        lesson.TimeSignatureMap = request.TimeSignatureMap;
        lesson.Tempo = request.Tempo;
        lesson.TheoryTitle = request.TheoryTitle;
        lesson.TheoryContent = request.TheoryContent;
        lesson.PracticeGuide = request.PracticeGuide;

        await db.SaveChangesAsync();
        return lesson;
    }

    public async Task DeleteAsync(long lessonId)
    {
        var lesson = await db.Lessons
            .Include(x => x.Notes)
            .FirstOrDefaultAsync(x => x.Id == lessonId);

        if (lesson == null)
            throw new Exception("Không tìm thấy bài học");

        var noteIds = lesson.Notes
            .Select(x => x.Id)
            .ToList();

        var attempts = await db.StudentNoteAttempts
            .Where(x => noteIds.Contains(x.LessonNoteId))
            .ToListAsync();

        db.StudentNoteAttempts.RemoveRange(attempts);

        var progresses = await db.StudentLessonProgresses
            .Where(x => x.LessonId == lessonId)
            .ToListAsync();

        db.StudentLessonProgresses.RemoveRange(progresses);

        db.Lessons.Remove(lesson);

        await db.SaveChangesAsync();
    }

    public async Task<LessonNote> AddNoteAsync(long lessonId, AddLessonNoteRequest request)
    {
        var lesson = await db.Lessons.FindAsync(lessonId);
        if (lesson == null)
            throw new Exception("Không tìm thấy bài học");

        var note = new LessonNote
        {
            LessonId = lessonId,
            Second = request.Second,
            StartBeat = request.StartBeat,
            DurationBeat = request.DurationBeat,
            Velocity = request.Velocity,
            Staff = request.Staff,
            Voice = request.Voice,
            Note = request.Note,
            Duration = request.Duration,
            Lyric = request.Lyric,
            Chord = request.Chord
        };

        db.LessonNotes.Add(note);
        await db.SaveChangesAsync();

        return note;
    }

    public async Task DeleteNoteAsync(long noteId)
    {
        var attempts = await db.StudentNoteAttempts
            .Where(x => x.LessonNoteId == noteId)
            .ToListAsync();

        db.StudentNoteAttempts.RemoveRange(attempts);

        var note = await db.LessonNotes.FindAsync(noteId);

        if (note != null)
            db.LessonNotes.Remove(note);

        await db.SaveChangesAsync();
    }

    public async Task<string> UploadAudioAsync(long lessonId, IFormFile file)
    {
        var lesson = await db.Lessons.FindAsync(lessonId);
        if (lesson == null)
            throw new Exception("Không tìm thấy bài học");

        var folder = Path.Combine(env.WebRootPath ?? "wwwroot", "uploads", "audio");
        Directory.CreateDirectory(folder);

        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var path = Path.Combine(folder, fileName);

        using var stream = new FileStream(path, FileMode.Create);
        await file.CopyToAsync(stream);

        var url = $"/uploads/audio/{fileName}";

        lesson.AudioUrl = url;
        lesson.AudioFileName = file.FileName;

        await db.SaveChangesAsync();

        return url;
    }

    public async Task SaveLessonContentAsync(
    long lessonId,
    SaveLessonContentRequest request)
    {
        var lesson = await db.Lessons
            .Include(x => x.Notes)
            .FirstOrDefaultAsync(x => x.Id == lessonId);

        if (lesson == null)
            throw new Exception("Không tìm thấy bài học");

        var noteIds = lesson.Notes
            .Select(x => x.Id)
            .ToList();

        // Xóa kết quả luyện tập
        var attempts = await db.StudentNoteAttempts
            .Where(x => noteIds.Contains(x.LessonNoteId))
            .ToListAsync();

        db.StudentNoteAttempts.RemoveRange(attempts);

        // Xóa toàn bộ note cũ
        db.LessonNotes.RemoveRange(lesson.Notes);

        await db.SaveChangesAsync();

        // Thêm lại toàn bộ note mới
        var newNotes = request.Notes.Select(x => new LessonNote
        {
            LessonId = lessonId,
            Second = x.Second,
            StartBeat = x.StartBeat,
            DurationBeat = x.DurationBeat,
            Velocity = x.Velocity,
            Staff = x.Staff,
            Voice = x.Voice,
            Note = x.Note,
            Duration = x.Duration,
            Lyric = x.Lyric,
            Chord = x.Chord
        });

        db.LessonNotes.AddRange(newNotes);

        await db.SaveChangesAsync();
    }

    public async Task PublishAsync(long lessonId)
    {
        var lesson = await db.Lessons.FindAsync(lessonId);

        if (lesson == null)
            throw new Exception("Không tìm thấy bài học");

        lesson.IsPublished = true;

        await db.SaveChangesAsync();
    }

    public async Task DeleteAllNotesAsync(long lessonId)
    {
        var notes = await db.LessonNotes
            .Where(x => x.LessonId == lessonId)
            .ToListAsync();

        var noteIds = notes
            .Select(x => x.Id)
            .ToList();

        var attempts = await db.StudentNoteAttempts
            .Where(x => noteIds.Contains(x.LessonNoteId))
            .ToListAsync();

        db.StudentNoteAttempts.RemoveRange(attempts);
        db.LessonNotes.RemoveRange(notes);

        await db.SaveChangesAsync();
    }
}
