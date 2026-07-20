namespace Music_IBook_API.Models
{
    public class AppUser
    {
        public long Id { get; set; }
        public string FullName { get; set; } = "";
        public string Email { get; set; } = "";
        
        // Nullable để các tài khoản Google cũ có thể chuyển sang mật khẩu bằng OTP.
        public string? PasswordHash { get; set; } 

        // Giữ lại để tương thích dữ liệu cũ; đăng nhập mới chỉ dùng Local.
        public string AuthProvider { get; set; } = "Local"; 

        // Dữ liệu legacy, được xóa khi người dùng đặt mật khẩu bằng OTP.
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
