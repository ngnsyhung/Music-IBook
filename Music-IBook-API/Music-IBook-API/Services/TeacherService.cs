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

    public async Task<TeacherDashboardDto> GetDashboardAsync()
    {
        var totalLessons = await db.Lessons.CountAsync();
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
                LastActivityAt = db.PracticeSessions.Where(ps => ps.StudentId == s.Id).Max(ps => (DateTime?)ps.StartedAtUtc)
            })
            .ToListAsync();

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
                    LastPracticeAt = practiceSessions.Max(x => (DateTime?)x.StartedAtUtc),
                    LastExamAt = examSessions.Max(x => (DateTime?)x.StartedAtUtc),
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
}
