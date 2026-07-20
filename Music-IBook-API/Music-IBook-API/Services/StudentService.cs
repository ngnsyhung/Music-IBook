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

        StudentAssignment? assignment = null;
        if (request.StudentAssignmentId.HasValue)
        {
            assignment = await db.StudentAssignments.FirstOrDefaultAsync(x =>
                x.Id == request.StudentAssignmentId.Value &&
                x.StudentId == studentId &&
                x.LessonId == request.LessonId);
            if (assignment == null)
                throw new ArgumentException("Bài tập bổ sung không thuộc học sinh hoặc bài học hiện tại.");
        }

        var finishedAtUtc = DateTime.UtcNow;
        var session = new PracticeSession
        {
            StudentId = studentId,
            LessonId = request.LessonId,
            IsExam = request.IsExam,
            DurationSeconds = request.DurationSeconds,
            StartedAtUtc = finishedAtUtc.AddSeconds(-Math.Max(0, request.DurationSeconds)),
            FinishedAtUtc = finishedAtUtc,
            CreatedAtUtc = finishedAtUtc
        };

        db.PracticeSessions.Add(session);
        await db.SaveChangesAsync();

        int correct = 0;
        int wrong = 0;
        int totalScore = 0;

        foreach (var attempt in request.Attempts)
        {
            var expected = lessonNotes.FirstOrDefault(x => x.Id == attempt.LessonNoteId);
            if (expected == null) continue;

            // Ưu tiên dùng JudgeResult từ client nếu có, fallback tính lại nếu thiếu
            var judgeResult = attempt.JudgeResult;
            if (string.IsNullOrEmpty(judgeResult))
            {
                var offsetMs = Math.Abs((attempt.PlayedAtSecond - expected.Second) * 1000);
                var correctPitch = attempt.PlayedNote == expected.Note;
                if (!correctPitch) judgeResult = "WRONG";
                else if (offsetMs < 100) judgeResult = "PERFECT";
                else if (offsetMs < 200) judgeResult = "GOOD";
                else if (offsetMs < 500) judgeResult = "LATE";
                else judgeResult = "MISS";
            }

            // Tính điểm theo JudgeResult
            int noteScore = judgeResult switch
            {
                "PERFECT" => 10,
                "GOOD"    => 8,
                "LATE"    => 5,
                "WRONG"   => -5,
                "MISS"    => -10,
                _         => 0
            };

            totalScore += noteScore;

            var isCorrect = judgeResult == "PERFECT" || judgeResult == "GOOD" || judgeResult == "LATE";
            if (isCorrect) correct++;
            else wrong++;

            var correctPitchFinal = attempt.PlayedNote == expected.Note;
            var timingErrorMs = string.IsNullOrEmpty(attempt.JudgeResult)
                ? Math.Abs((attempt.PlayedAtSecond - expected.Second) * 1000)
                : attempt.TimingErrorMs;

            db.StudentNoteAttempts.Add(new StudentNoteAttempt
            {
                PracticeSessionId = session.Id,
                LessonNoteId = expected.Id,
                ExpectedNote = expected.Note,
                PlayedNote = attempt.PlayedNote,
                ExpectedAtSecond = expected.Second,
                PlayedAtSecond = attempt.PlayedAtSecond,
                TimingErrorMs = timingErrorMs,
                IsCorrectPitch = correctPitchFinal,
                IsCorrectTiming = judgeResult is "PERFECT" or "GOOD" or "LATE",
                IsCorrect = isCorrect,
                JudgeResult = judgeResult,
                CreatedAtUtc = DateTime.UtcNow
            });
        }

        var total = correct + wrong;

        session.CorrectCount = correct;
        session.WrongCount = wrong;
        session.Accuracy = total == 0 ? 0 : Math.Round((double)correct / total * 100, 2);
        // Điểm tối đa = số nốt * 10, không âm
        session.Score = Math.Max(0, totalScore);

        if (assignment != null)
            assignment.IsCompleted = true;

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

    public async Task<List<AssignmentDto>> GetAssignmentsAsync(long studentId, long? lessonId)
    {
        var query = db.StudentAssignments
            .Where(x => x.StudentId == studentId);
        if (lessonId.HasValue)
            query = query.Where(x => x.LessonId == lessonId.Value);

        var assignments = await query
            .OrderBy(x => x.IsCompleted)
            .ThenBy(x => x.DueAtUtc)
            .ThenByDescending(x => x.CreatedAtUtc)
            .Select(x => new AssignmentDto
            {
                Id = x.Id,
                StudentId = x.StudentId,
                LessonId = x.LessonId,
                LessonSectionId = x.LessonSectionId,
                LessonExerciseId = x.LessonExerciseId,
                SectionTitle = x.Section == null ? null : x.Section.Title,
                ExerciseTitle = x.Exercise == null ? null : x.Exercise.Title,
                Message = x.Message,
                DueAtUtc = x.DueAtUtc,
                CreatedAtUtc = x.CreatedAtUtc,
                IsCompleted = x.IsCompleted
            })
            .ToListAsync();

        foreach (var assignment in assignments)
        {
            assignment.DueAtUtc = AsUtc(assignment.DueAtUtc);
            assignment.CreatedAtUtc = AsUtc(assignment.CreatedAtUtc)!.Value;
        }
        return assignments;
    }

    private static DateTime? AsUtc(DateTime? value) => value.HasValue
        ? DateTime.SpecifyKind(value.Value, DateTimeKind.Utc)
        : null;
}
