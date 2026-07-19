using System.Text.Json.Serialization;

namespace Music_IBook_API.Models
{
    public class LessonNote
    {
        public long Id { get; set; }
        public long LessonId { get; set; }

        public double Second { get; set; }
        public double StartBeat { get; set; } = 1;
        public double DurationBeat { get; set; } = 1;
        public int Velocity { get; set; } = 90;
        public int Staff { get; set; }
        public int Voice { get; set; }
        public string Note { get; set; } = "";       // C4, D4, F#4...
        public string Duration { get; set; } = "";   // eighth, quarter, half
        public string Lyric { get; set; } = "";
        public string Chord { get; set; } = "";

        [JsonIgnore]
        public MusicLesson Lesson { get; set; } = null!;
        public ICollection<StudentNoteAttempt> StudentNoteAttempts { get; set; }
            = new List<StudentNoteAttempt>();
    }
}
