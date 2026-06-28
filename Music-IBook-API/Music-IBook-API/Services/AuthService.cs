using Music_IBook_API.DTOs;
using Music_IBook_API.Helpers;
using Music_IBook_API.Models;
using Music_IBook_API.Repositories;
// Cần cài thêm package: Google.Apis.Auth để dùng thư viện dưới đây
// using Google.Apis.Auth; 

namespace Music_IBook_API.Services;

public class AuthService : IAuthService
{
    private readonly IRepository<AppUser> userRepo;
    private readonly IRepository<PasswordResetToken> tokenRepo;
    private readonly JwtHelper jwt;

    public AuthService(
        IRepository<AppUser> userRepo,
        IRepository<PasswordResetToken> tokenRepo,
        JwtHelper jwt)
    {
        this.userRepo = userRepo;
        this.tokenRepo = tokenRepo;
        this.jwt = jwt;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        var existed = await userRepo.FirstOrDefaultAsync(x => x.Email == request.Email);
        if (existed != null)
            throw new Exception("Email đã tồn tại");

        var user = new AppUser
        {
            FullName = request.FullName,
            Email = request.Email,
            Role = request.Role,
            AuthProvider = "Local", // Đảm bảo gán rõ nguồn
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password)
        };

        await userRepo.AddAsync(user);
        await userRepo.SaveChangesAsync();

        return new AuthResponse
        {
            AccessToken = jwt.GenerateToken(user),
            FullName = user.FullName,
            Role = user.Role
        };
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        var user = await userRepo.FirstOrDefaultAsync(x => x.Email == request.Email);

        // VÁ LỖI: Chặn user Google dùng form đăng nhập thường
        if (user != null && user.AuthProvider == "Google" && string.IsNullOrEmpty(user.PasswordHash))
            throw new Exception("Tài khoản này dùng Google. Vui lòng chọn 'Đăng nhập bằng Google'.");

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new Exception("Email hoặc mật khẩu không đúng");

        return new AuthResponse
        {
            AccessToken = jwt.GenerateToken(user),
            FullName = user.FullName,
            Role = user.Role
        };
    }

    public async Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request)
    {
        // 1. Cài package Google.Apis.Auth và bật 3 dòng code này lên để verify Token thật từ Flutter gửi lên:
        // var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken);
        // var email = payload.Email;
        // var name = payload.Name;
        // var providerKey = payload.Subject;

        // Dữ liệu Mock tạm thời để bạn test logic trước khi nối App Flutter:
        var email = "test_google@gmail.com";
        var name = "Google User";
        var providerKey = "google_123456";

        var user = await userRepo.FirstOrDefaultAsync(x => x.Email == email);

        // Nếu user chưa từng đăng nhập -> Tạo mới
        if (user == null)
        {
            user = new AppUser
            {
                FullName = name,
                Email = email,
                Role = "Student", // Mặc định Google Login là Student
                PasswordHash = null,
                AuthProvider = "Google",
                ProviderKey = providerKey
            };
            await userRepo.AddAsync(user);
            await userRepo.SaveChangesAsync();
        }
        else if (user.AuthProvider != "Google")
        {
            // Nếu email này đã đăng ký tay từ trước, báo lỗi để tránh xung đột
            throw new Exception("Email này đã được sử dụng bằng tài khoản thường.");
        }

        return new AuthResponse
        {
            AccessToken = jwt.GenerateToken(user),
            FullName = user.FullName,
            Role = user.Role
        };
    }

    public async Task<string> ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        var user = await userRepo.FirstOrDefaultAsync(x => x.Email == request.Email);
        if (user == null)
            throw new Exception("Không tìm thấy email");

        // VÁ LỖI: Chặn user Google xin cấp lại mật khẩu
        if (user.AuthProvider == "Google")
            throw new Exception("Tài khoản Google không thể đổi mật khẩu tại đây.");

        var resetToken = new PasswordResetToken
        {
            UserId = user.Id,
            Token = Guid.NewGuid().ToString("N"),
            ExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            IsUsed = false
        };

        await tokenRepo.AddAsync(resetToken);
        await tokenRepo.SaveChangesAsync();

        return resetToken.Token;
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        var token = await tokenRepo.FirstOrDefaultAsync(x =>
            x.Token == request.Token &&
            !x.IsUsed &&
            x.ExpiresAtUtc > DateTime.UtcNow);

        if (token == null)
            throw new Exception("Token không hợp lệ hoặc đã hết hạn");

        var user = await userRepo.GetByIdAsync(token.UserId);
        if (user == null)
            throw new Exception("Không tìm thấy người dùng");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        token.IsUsed = true;

        userRepo.Update(user);
        tokenRepo.Update(token);

        await userRepo.SaveChangesAsync();
    }
}