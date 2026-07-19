namespace Music_IBook_API.Models
{
    public class MusicLesson
    {
        public long Id { get; set; }
        public long TeacherId { get; set; }

        public string Title { get; set; } = "";
        public string Composer { get; set; } = "";
        public string Clef { get; set; } = "treble";
        public string KeySignature { get; set; } = "D Major";
        public string TimeSignature { get; set; } = "2/4";
        public string TimeSignatureMap { get; set; } = "";
        public int Tempo { get; set; } = 80;

        public string TheoryTitle { get; set; } = "";
        public string TheoryContent { get; set; } = "";
        public string PracticeGuide { get; set; } = "";

        public string? AudioUrl { get; set; }
        public string? AudioFileName { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
        public bool IsPublished { get; set; }

        public AppUser Teacher { get; set; } = null!;
        public ICollection<LessonNote> Notes { get; set; } = [];
    }
}
