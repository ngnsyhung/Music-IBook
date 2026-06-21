namespace Music_IBook_API.Models
{
    public class PracticeSessionDetail
    {
        public long Id { get; set; }
        public long PracticeSessionId { get; set; }
        public long LessonNoteId { get; set; }

        public string ExpectedNote { get; set; } = "";
        public string PressedNote { get; set; } = "";
        public bool IsCorrect { get; set; }
        public double PressedAtSecond { get; set; }

        public PracticeSession PracticeSession { get; set; } = null!;
        public LessonNote LessonNote { get; set; } = null!;
    }
}
