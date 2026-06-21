namespace Music_IBook_API.Models
{
    public class StudentLessonProgress
    {
        public long Id { get; set; }
        public long StudentId { get; set; }
        public long LessonId { get; set; }

        public double LastPositionSecond { get; set; }
        public int CompletedNoteCount { get; set; }
        public int BestScore { get; set; }
        public int TotalAttempts { get; set; }
        public bool IsCompleted { get; set; }

        public DateTime LastStudiedAtUtc { get; set; } = DateTime.UtcNow;

        public AppUser Student { get; set; } = null!;
        public MusicLesson Lesson { get; set; } = null!;
    }
}
