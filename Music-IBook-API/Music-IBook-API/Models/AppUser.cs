namespace Music_IBook_API.Models
{
    public class AppUser
    {
        public long Id { get; set; }
        public string FullName { get; set; } = "";
        public string Email { get; set; } = "";
        
        // Cập nhật: Cho phép null để hỗ trợ tài khoản đăng nhập từ Google
        public string? PasswordHash { get; set; } 

        // Cập nhật: Lưu nguồn đăng nhập ("Local" hoặc "Google")
        public string AuthProvider { get; set; } = "Local"; 

        // Cập nhật: Lưu ID định danh do Google trả về
        public string? ProviderKey { get; set; } 

        public string Role { get; set; } = "Student"; // Teacher, Student
        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

        // --- Navigation Properties (Liên kết bảng trong Entity Framework) ---
        public ICollection<MusicLesson> LessonsCreated { get; set; } = [];
        public ICollection<StudentLessonProgress> Progresses { get; set; } = [];
        
        // Cập nhật: Thêm danh sách token để EF Core hiểu quan hệ 1-N
        public ICollection<PasswordResetToken> PasswordResetTokens { get; set; } = [];
    }
}