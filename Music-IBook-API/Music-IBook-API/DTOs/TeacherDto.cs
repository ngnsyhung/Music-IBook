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

public class PracticeSessionTrendDto
{
    public long SessionId { get; set; }
    public bool IsExam { get; set; }
    public int Score { get; set; }
    public double Accuracy { get; set; }
    public int CorrectCount { get; set; }
    public int WrongCount { get; set; }
    public DateTime StartedAtUtc { get; set; }
}

public class NoteErrorDto
{
    public string Note { get; set; } = "";
    public int ErrorCount { get; set; }
    public int WrongPitchCount { get; set; }
    public int TimingErrorCount { get; set; }
}

public class AssignmentDto
{
    public long Id { get; set; }
    public long StudentId { get; set; }
    public long LessonId { get; set; }
    public long? LessonSectionId { get; set; }
    public long? LessonExerciseId { get; set; }
    public string? SectionTitle { get; set; }
    public string? ExerciseTitle { get; set; }
    public string Message { get; set; } = "";
    public DateTime? DueAtUtc { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public bool IsCompleted { get; set; }
}

public class LessonAnalyticsDto
{
    public long StudentId { get; set; }
    public long LessonId { get; set; }
    public List<PracticeSessionTrendDto> Sessions { get; set; } = [];
    public List<NoteErrorDto> ErrorNotes { get; set; } = [];
    public List<AssignmentDto> Assignments { get; set; } = [];
}

public class CreateStudentAssignmentRequest
{
    public long StudentId { get; set; }
    public long LessonId { get; set; }
    public long? LessonSectionId { get; set; }
    public long? LessonExerciseId { get; set; }
    public string Message { get; set; } = "";
    public DateTime? DueAtUtc { get; set; }
}
