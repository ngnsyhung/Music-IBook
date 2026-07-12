namespace Music_IBook_API.DTOs;

public class SaveProgressRequest
{
    public double LastPositionSecond { get; set; }
    public int CompletedNoteCount { get; set; }
    public int BestScore { get; set; }
    public bool IsCompleted { get; set; }
}

public class SubmitPracticeRequest
{
    public long LessonId { get; set; }
    public bool IsExam { get; set; }
    public int DurationSeconds { get; set; }
    public List<SubmitNoteAttemptRequest> Attempts { get; set; } = [];
}

public class SubmitNoteAttemptRequest
{
    public long LessonNoteId { get; set; }
    public string PlayedNote { get; set; } = "";
    public double PlayedAtSecond { get; set; }
    public string JudgeResult { get; set; } = ""; // PERFECT, GOOD, LATE, WRONG, MISS
    public double TimingErrorMs { get; set; }
}