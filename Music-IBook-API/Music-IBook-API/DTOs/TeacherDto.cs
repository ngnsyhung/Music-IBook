namespace Music_IBook_API.DTOs;

public class TeacherDashboardDto
{
    public int TotalLessons { get; set; }
    public int TotalStudents { get; set; }
    public int TotalPracticeSessions { get; set; }
    public int TotalExamSessions { get; set; }
    public double AverageSystemScore { get; set; }
}

public class StudentProgressOverviewDto
{
    public long StudentId { get; set; }
    public string StudentName { get; set; } = "";
    public string Email { get; set; } = "";
    public int LessonCount { get; set; }
    public int ExamCount { get; set; }
    public double AverageScore { get; set; }
    public DateTime? LastActivityAt { get; set; }
}

public class StudentDetailProgressDto
{
    public long StudentId { get; set; }
    public string StudentName { get; set; } = "";
    public List<LessonProgressDetailDto> Lessons { get; set; } = [];
}

public class LessonProgressDetailDto
{
    public long LessonId { get; set; }
    public string LessonName { get; set; } = "";
    public DateTime? LastPracticeAt { get; set; }
    public DateTime? LastExamAt { get; set; }
    public int HighestScore { get; set; }
    public double AverageScore { get; set; }
    public double Accuracy { get; set; }
}
