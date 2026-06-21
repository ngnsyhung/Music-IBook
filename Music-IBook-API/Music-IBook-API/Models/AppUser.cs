namespace Music_IBook_API.Models
{
    public class AppUser
    {
        public long Id { get; set; }
        public string FullName { get; set; } = "";
        public string Email { get; set; } = "";
        public string PasswordHash { get; set; } = "";
        public string Role { get; set; } = "Student"; // Teacher, Student
        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

        public ICollection<MusicLesson> LessonsCreated { get; set; } = [];
        public ICollection<StudentLessonProgress> Progresses { get; set; } = [];
    }
}
