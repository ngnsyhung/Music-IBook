namespace Music_IBook_API.Models
{
    public class PasswordResetToken
    {
        public long Id { get; set; }
        public long UserId { get; set; }
        public string Token { get; set; } = "";
        public DateTime ExpiresAtUtc { get; set; }
        public bool IsUsed { get; set; }

        public AppUser User { get; set; } = null!;
    }
}
