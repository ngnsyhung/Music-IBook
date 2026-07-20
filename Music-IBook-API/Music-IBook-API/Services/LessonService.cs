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
            .AsNoTracking()
            // Loading several child collections in one SQL query multiplies the
            // result rows (notes x sections x annotations x exercises). MIDI
            // lessons can contain thousands of notes, so use one query per
            // collection while preserving the existing response contract.
            .AsSplitQuery()
            .Include(x => x.Notes.OrderBy(n => n.StartBeat).ThenBy(n => n.Note))
            .Include(x => x.Sections.OrderBy(s => s.SortOrder))
            .Include(x => x.Annotations.OrderBy(a => a.StartBeat))
            .Include(x => x.Exercises.OrderBy(e => e.SortOrder))
            .Where(x => x.IsPublished)
            .ToListAsync();
    }

    public async Task<List<MusicLesson>> GetForTeacherAsync(long teacherId)
    {
        return await db.Lessons
            .AsNoTracking()
            .AsSplitQuery()
            .Include(x => x.Notes.OrderBy(n => n.StartBeat).ThenBy(n => n.Note))
            .Include(x => x.Sections.OrderBy(s => s.SortOrder))
            .Include(x => x.Annotations.OrderBy(a => a.StartBeat))
            .Include(x => x.Exercises.OrderBy(e => e.SortOrder))
            .Where(x => x.TeacherId == teacherId)
            .OrderByDescending(x => x.CreatedAtUtc)
            .ToListAsync();
    }

    public async Task<MusicLesson?> GetByIdAsync(long id)
    {
        return await db.Lessons
            .AsNoTracking()
            .AsSplitQuery()
            .Include(x => x.Notes.OrderBy(n => n.StartBeat).ThenBy(n => n.Note))
            .Include(x => x.Sections.OrderBy(s => s.SortOrder))
            .Include(x => x.Annotations.OrderBy(a => a.StartBeat))
            .Include(x => x.Exercises.OrderBy(e => e.SortOrder))
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
            TempoMap = request.TempoMap,
            Tempo = request.Tempo,
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
        lesson.TempoMap = request.TempoMap;
        lesson.Tempo = request.Tempo;

        await db.SaveChangesAsync();
        return lesson;
    }

    public async Task DeleteAsync(long lessonId)
    {
        var lesson = await db.Lessons
            .Include(x => x.Notes)
            .Include(x => x.Sections)
            .Include(x => x.Annotations)
            .Include(x => x.Exercises)
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

        // StudentAssignments and LessonExercises both use restrictive lesson
        // foreign keys. Mark every dependent explicitly so EF can order the
        // DELETE statements without severing a required tracked relationship.
        var assignments = await db.StudentAssignments
            .Where(x => x.LessonId == lessonId)
            .ToListAsync();
        db.StudentAssignments.RemoveRange(assignments);

        var practiceSessions = await db.PracticeSessions
            .Where(x => x.LessonId == lessonId)
            .ToListAsync();
        db.PracticeSessions.RemoveRange(practiceSessions);

        db.LessonExercises.RemoveRange(lesson.Exercises);
        db.LessonAnnotations.RemoveRange(lesson.Annotations);
        db.LessonSections.RemoveRange(lesson.Sections);
        db.LessonNotes.RemoveRange(lesson.Notes);

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
            Track = request.Track,
            TrackName = request.TrackName,
            Staff = request.Staff,
            Voice = request.Voice,
            Note = request.Note,
            Duration = request.Duration,
            Lyric = request.Lyric,
            Chord = request.Chord,
            Fingering = request.Fingering
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
            .Include(x => x.Sections)
            .Include(x => x.Annotations)
            .Include(x => x.Exercises)
            .FirstOrDefaultAsync(x => x.Id == lessonId);

        if (lesson == null)
            throw new Exception("Không tìm thấy bài học");

        var noteIds = lesson.Notes
            .Select(x => x.Id)
            .ToList();

        if (request.Sections.Any(x =>
                string.IsNullOrWhiteSpace(x.Title) ||
                x.StartBeat < 1 ||
                x.EndBeat < x.StartBeat ||
                x.DefaultTempo is < 30 or > 300))
        {
            throw new ArgumentException("Dữ liệu đoạn luyện tập không hợp lệ.");
        }

        if (request.Sections.GroupBy(x => x.SortOrder).Any(x => x.Count() > 1))
        {
            throw new ArgumentException("Thứ tự các đoạn luyện tập phải là duy nhất.");
        }

        await using var transaction = await db.Database.BeginTransactionAsync();

        // Một thay đổi toàn bộ khuông nhạc tạo các ID nốt mới. Kết quả chấm
        // theo nốt cũ không còn chính xác nên được dọn cùng lúc, thay vì để
        // lại dữ liệu lỗi thời hoặc mồ côi.
        var attempts = await db.StudentNoteAttempts
            .Where(x => noteIds.Contains(x.LessonNoteId))
            .ToListAsync();

        db.StudentNoteAttempts.RemoveRange(attempts);

        db.LessonNotes.RemoveRange(lesson.Notes);
        db.LessonExercises.RemoveRange(lesson.Exercises);
        db.LessonAnnotations.RemoveRange(lesson.Annotations);
        db.LessonSections.RemoveRange(lesson.Sections);

        await db.SaveChangesAsync();

        // Add the score and authoring metadata in one API request. Exercises
        // use SortOrder while saving so they can refer to newly-created sections.
        var newNotes = request.Notes.Select(x => new LessonNote
        {
            LessonId = lessonId,
            Second = x.Second,
            StartBeat = x.StartBeat,
            DurationBeat = x.DurationBeat,
            Velocity = x.Velocity,
            Track = x.Track,
            TrackName = x.TrackName,
            Staff = x.Staff,
            Voice = x.Voice,
            Note = x.Note,
            Duration = x.Duration,
            Lyric = x.Lyric,
            Chord = x.Chord,
            Fingering = x.Fingering
        });

        db.LessonNotes.AddRange(newNotes);

        var newSections = request.Sections.Select(x => new LessonSection
        {
            LessonId = lessonId,
            Title = x.Title.Trim(),
            StartBeat = x.StartBeat,
            EndBeat = x.EndBeat,
            DefaultTempo = x.DefaultTempo,
            Difficulty = x.Difficulty,
            Hand = x.Hand,
            SortOrder = x.SortOrder
        }).ToList();
        db.LessonSections.AddRange(newSections);

        var newAnnotations = request.Annotations
            .Where(x => !string.IsNullOrWhiteSpace(x.Text))
            .Select(x => new LessonAnnotation
            {
                LessonId = lessonId,
                StartBeat = Math.Max(1, x.StartBeat),
                EndBeat = x.EndBeat,
                Kind = x.Kind,
                Text = x.Text.Trim()
            });
        db.LessonAnnotations.AddRange(newAnnotations);

        await db.SaveChangesAsync();

        var sectionsByOrder = newSections.ToDictionary(x => x.SortOrder);
        var newExercises = request.Exercises
            .Where(x => !string.IsNullOrWhiteSpace(x.Title))
            .Select(x => new LessonExercise
            {
                LessonId = lessonId,
                LessonSectionId = x.SectionSortOrder.HasValue &&
                                  sectionsByOrder.TryGetValue(x.SectionSortOrder.Value, out var section)
                    ? section.Id
                    : null,
                Title = x.Title.Trim(),
                Type = x.Type,
                Instruction = x.Instruction.Trim(),
                ConfigJson = string.IsNullOrWhiteSpace(x.ConfigJson) ? "{}" : x.ConfigJson,
                SortOrder = x.SortOrder
            });
        db.LessonExercises.AddRange(newExercises);

        await db.SaveChangesAsync();
        await transaction.CommitAsync();
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
