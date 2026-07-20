using Microsoft.EntityFrameworkCore;
using Music_IBook_API.DTOs;
using Music_IBook_API.Models;

namespace Music_IBook_API.Services;

public class TeacherService : ITeacherService
{
    private readonly MusicIBookDbContext db;

    public TeacherService(MusicIBookDbContext db)
    {
        this.db = db;
    }

    public async Task<TeacherDashboardDto> GetDashboardAsync(long teacherId)
    {
        var totalLessons = await db.Lessons.CountAsync(x => x.TeacherId == teacherId);
        var totalStudents = await db.Users.CountAsync(x => x.Role == "Student");
        var totalPracticeSessions = await db.PracticeSessions.CountAsync(x => !x.IsExam);
        var totalExamSessions = await db.PracticeSessions.CountAsync(x => x.IsExam);
        
        var avgScore = await db.PracticeSessions
            .Where(x => x.IsExam)
            .AverageAsync(x => (double?)x.Score) ?? 0;

        return new TeacherDashboardDto
        {
            TotalLessons = totalLessons,
            TotalStudents = totalStudents,
            TotalPracticeSessions = totalPracticeSessions,
            TotalExamSessions = totalExamSessions,
            AverageSystemScore = Math.Round(avgScore, 2)
        };
    }

    public async Task<List<StudentProgressOverviewDto>> GetStudentsProgressAsync()
    {
        var students = await db.Users
            .Where(x => x.Role == "Student")
            .Select(s => new StudentProgressOverviewDto
            {
                StudentId = s.Id,
                StudentName = s.FullName,
                Email = s.Email,
                LessonCount = db.PracticeSessions.Where(ps => ps.StudentId == s.Id && !ps.IsExam).Select(ps => ps.LessonId).Distinct().Count(),
                ExamCount = db.PracticeSessions.Where(ps => ps.StudentId == s.Id && ps.IsExam).Count(),
                AverageScore = db.PracticeSessions.Where(ps => ps.StudentId == s.Id && ps.IsExam).Average(ps => (double?)ps.Score) ?? 0,
                LastActivityAt = db.PracticeSessions
                    .Where(ps => ps.StudentId == s.Id)
                    .Max(ps => (DateTime?)(ps.FinishedAtUtc ?? ps.StartedAtUtc))
            })
            .ToListAsync();

        foreach (var student in students)
            student.LastActivityAt = AsUtc(student.LastActivityAt);
        return students;
    }

    public async Task<StudentDetailProgressDto> GetStudentProgressDetailAsync(long studentId)
    {
        var student = await db.Users.FindAsync(studentId);
        if (student == null) throw new Exception("Không tìm thấy học sinh");

        var lessons = await db.Lessons.ToListAsync();
        var sessions = await db.PracticeSessions
            .Where(x => x.StudentId == studentId)
            .ToListAsync();

        var lessonProgresses = new List<LessonProgressDetailDto>();

        foreach (var lesson in lessons)
        {
            var lessonSessions = sessions.Where(s => s.LessonId == lesson.Id).ToList();
            var practiceSessions = lessonSessions.Where(s => !s.IsExam).ToList();
            var examSessions = lessonSessions.Where(s => s.IsExam).ToList();

            if (lessonSessions.Any())
            {
                lessonProgresses.Add(new LessonProgressDetailDto
                {
                    LessonId = lesson.Id,
                    LessonName = lesson.Title,
                    LastPracticeAt = practiceSessions.Any()
                        ? AsUtc(practiceSessions.Max(x => x.FinishedAtUtc ?? x.StartedAtUtc))
                        : null,
                    LastExamAt = examSessions.Any()
                        ? AsUtc(examSessions.Max(x => x.FinishedAtUtc ?? x.StartedAtUtc))
                        : null,
                    HighestScore = examSessions.Any() ? examSessions.Max(x => x.Score) : 0,
                    AverageScore = examSessions.Any() ? Math.Round(examSessions.Average(x => x.Score), 2) : 0,
                    Accuracy = examSessions.Any() ? Math.Round(examSessions.Average(x => x.Accuracy), 2) : 0
                });
            }
        }

        return new StudentDetailProgressDto
        {
            StudentId = student.Id,
            StudentName = student.FullName,
            Lessons = lessonProgresses.OrderByDescending(x => x.LastExamAt ?? x.LastPracticeAt).ToList()
        };
    }

    public async Task<LessonAnalyticsDto> GetLessonAnalyticsAsync(long studentId, long lessonId)
    {
        var studentExists = await db.Users.AnyAsync(x => x.Id == studentId && x.Role == "Student");
        var lessonExists = await db.Lessons.AnyAsync(x => x.Id == lessonId);
        if (!studentExists || !lessonExists)
            throw new Exception("Không tìm thấy học sinh hoặc bài học");

        var sessions = await db.PracticeSessions
            .Where(x => x.StudentId == studentId && x.LessonId == lessonId)
            .OrderByDescending(x => x.StartedAtUtc)
            .Take(30)
            .Select(x => new PracticeSessionTrendDto
            {
                SessionId = x.Id,
                IsExam = x.IsExam,
                Score = x.Score,
                Accuracy = x.Accuracy,
                CorrectCount = x.CorrectCount,
                WrongCount = x.WrongCount,
                StartedAtUtc = x.StartedAtUtc
            })
            .ToListAsync();

        sessions.Reverse();
        foreach (var session in sessions)
            session.StartedAtUtc = AsUtc(session.StartedAtUtc)!.Value;

        var errorNotes = await db.StudentNoteAttempts
            .Where(x => x.PracticeSession.StudentId == studentId &&
                        x.PracticeSession.LessonId == lessonId &&
                        !x.IsCorrect)
            .GroupBy(x => x.ExpectedNote)
            .Select(x => new NoteErrorDto
            {
                Note = x.Key,
                ErrorCount = x.Count(),
                WrongPitchCount = x.Count(a => !a.IsCorrectPitch),
                TimingErrorCount = x.Count(a => !a.IsCorrectTiming)
            })
            .OrderByDescending(x => x.ErrorCount)
            .ThenBy(x => x.Note)
            .Take(12)
            .ToListAsync();

        var assignments = await db.StudentAssignments
            .Where(x => x.StudentId == studentId && x.LessonId == lessonId)
            .OrderByDescending(x => x.CreatedAtUtc)
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

        return new LessonAnalyticsDto
        {
            StudentId = studentId,
            LessonId = lessonId,
            Sessions = sessions,
            ErrorNotes = errorNotes,
            Assignments = assignments
        };
    }

    public async Task<AssignmentDto> CreateStudentAssignmentAsync(CreateStudentAssignmentRequest request)
    {
        var studentExists = await db.Users.AnyAsync(x => x.Id == request.StudentId && x.Role == "Student");
        var lessonExists = await db.Lessons.AnyAsync(x => x.Id == request.LessonId);
        if (!studentExists || !lessonExists)
            throw new Exception("Không tìm thấy học sinh hoặc bài học");

        if (request.LessonSectionId.HasValue && !await db.LessonSections.AnyAsync(x =>
                x.Id == request.LessonSectionId.Value && x.LessonId == request.LessonId))
            throw new ArgumentException("Đoạn luyện tập không thuộc bài học đã chọn.");

        if (request.LessonExerciseId.HasValue && !await db.LessonExercises.AnyAsync(x =>
                x.Id == request.LessonExerciseId.Value && x.LessonId == request.LessonId))
            throw new ArgumentException("Bài tập không thuộc bài học đã chọn.");

        var assignment = new StudentAssignment
        {
            StudentId = request.StudentId,
            LessonId = request.LessonId,
            LessonSectionId = request.LessonSectionId,
            LessonExerciseId = request.LessonExerciseId,
            Message = request.Message.Trim(),
            DueAtUtc = request.DueAtUtc,
            CreatedAtUtc = DateTime.UtcNow
        };
        db.StudentAssignments.Add(assignment);
        await db.SaveChangesAsync();

        return new AssignmentDto
        {
            Id = assignment.Id,
            StudentId = assignment.StudentId,
            LessonId = assignment.LessonId,
            LessonSectionId = assignment.LessonSectionId,
            LessonExerciseId = assignment.LessonExerciseId,
            Message = assignment.Message,
            DueAtUtc = assignment.DueAtUtc,
            CreatedAtUtc = assignment.CreatedAtUtc,
            IsCompleted = assignment.IsCompleted
        };
    }

    private static DateTime? AsUtc(DateTime? value) => value.HasValue
        ? DateTime.SpecifyKind(value.Value, DateTimeKind.Utc)
        : null;
}
