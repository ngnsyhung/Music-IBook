namespace Music_IBook_API.Models
{
    public class StudentNoteAttempt
    {
        public long Id { get; set; }

        public long PracticeSessionId { get; set; }

        public long LessonNoteId { get; set; }

        public string ExpectedNote { get; set; } = "";

        public string PlayedNote { get; set; } = "";

        public double ExpectedAtSecond { get; set; }

        public double PlayedAtSecond { get; set; }

        public double TimingErrorMs { get; set; }

        public bool IsCorrectPitch { get; set; }

        public bool IsCorrectTiming { get; set; }

        public bool IsCorrect { get; set; }

        public string JudgeResult { get; set; } = ""; // PERFECT, GOOD, LATE, WRONG, MISS

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

        public PracticeSession PracticeSession { get; set; } = null!;

        public LessonNote LessonNote { get; set; } = null!;
    }
}
