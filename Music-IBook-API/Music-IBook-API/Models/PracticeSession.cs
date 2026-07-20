namespace Music_IBook_API.Models
{
    public class PracticeSession
    {
        public long Id { get; set; }
        public long StudentId { get; set; }
        public long LessonId { get; set; }

        public bool IsExam { get; set; }

        public int Score { get; set; }
        public int CorrectCount { get; set; }
        public int WrongCount { get; set; }
        public double Accuracy { get; set; }

        public int DurationSeconds { get; set; }

        public DateTime StartedAtUtc { get; set; } = DateTime.UtcNow;
        public DateTime? FinishedAtUtc { get; set; }
        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

        public AppUser Student { get; set; } = null!;
        public MusicLesson Lesson { get; set; } = null!;
        public ICollection<StudentNoteAttempt> NoteAttempts { get; set; } = new List<StudentNoteAttempt>();
    }
}
