using System.Text.RegularExpressions;
using Music_IBook_API.DTOs;
using Music_IBook_API.Helpers;
using Music_IBook_API.Models;
using Music_IBook_API.Repositories;
using Google.Apis.Auth;

namespace Music_IBook_API.Services;

public class AuthService : IAuthService
{
    private static readonly Regex EmailRegex = new(
        "^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$",
        RegexOptions.Compiled);

    private readonly IRepository<AppUser> userRepo;
    private readonly IRepository<PasswordResetToken> tokenRepo;
    private readonly JwtHelper jwt;
    private readonly IConfiguration config;

    public AuthService(
        IRepository<AppUser> userRepo,
        IRepository<PasswordResetToken> tokenRepo,
        JwtHelper jwt,
        IConfiguration config)
    {
        this.userRepo = userRepo;
        this.tokenRepo = tokenRepo;
        this.jwt = jwt;
        this.config = config;
    }

    private static bool IsValidEmail(string email)
    {
        return !string.IsNullOrWhiteSpace(email) && EmailRegex.IsMatch(email.Trim());
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ArgumentException("Email không được để trống");

        if (!IsValidEmail(request.Email))
            throw new ArgumentException("Email không hợp lệ");

        if (string.IsNullOrWhiteSpace(request.Password))
            throw new ArgumentException("Mật khẩu không được để trống");

        if (string.IsNullOrWhiteSpace(request.FullName))
            throw new ArgumentException("Họ tên không được để trống");

        if (string.Equals(request.Role, "Student", StringComparison.OrdinalIgnoreCase))
        {
            request.Role = "Student";
        }
        else if (string.Equals(request.Role, "Teacher", StringComparison.OrdinalIgnoreCase))
        {
            request.Role = "Teacher";
        }
        else
        {
            throw new ArgumentException("Vai trò không hợp lệ. Chỉ chấp nhận 'Student' hoặc 'Teacher'.");
        }

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
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            throw new UnauthorizedAccessException("Email hoặc mật khẩu không đúng");

        if (!IsValidEmail(request.Email))
            throw new UnauthorizedAccessException("Email hoặc mật khẩu không đúng");

        var user = await userRepo.FirstOrDefaultAsync(x => x.Email == request.Email);

        // VÁ LỖI: Chặn user Google dùng form đăng nhập thường
        if (user != null && user.AuthProvider == "Google" && string.IsNullOrEmpty(user.PasswordHash))
            throw new Exception("Tài khoản này dùng Google. Vui lòng chọn 'Đăng nhập bằng Google'.");

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Email hoặc mật khẩu không đúng");

        return new AuthResponse
        {
            AccessToken = jwt.GenerateToken(user),
            FullName = user.FullName,
            Role = user.Role
        };
    }

    public async Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.IdToken))
            throw new ArgumentException("Token Google không hợp lệ");

        GoogleJsonWebSignature.Payload payload;
        try
        {
            var googleClientId = config["Google:ClientId"];
            if (string.IsNullOrWhiteSpace(googleClientId) || googleClientId == "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com")
            {
                throw new InvalidOperationException("Chưa cấu hình Google Client ID hợp lệ trong appsettings.json.");
            }

            var validationSettings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = new[] { googleClientId }
            };
            payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, validationSettings);
        }
        catch (InvalidJwtException ex)
        {
            throw new UnauthorizedAccessException($"Token Google không hợp lệ hoặc đã hết hạn: {ex.Message}", ex);
        }

        var email = payload.Email;
        var name = payload.Name;
        var providerKey = payload.Subject;

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
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ArgumentException("Email không được để trống");

        if (!IsValidEmail(request.Email))
            throw new ArgumentException("Email không hợp lệ");

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
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (string.IsNullOrWhiteSpace(request.Token))
            throw new ArgumentException("Token không được để trống");

        if (string.IsNullOrWhiteSpace(request.NewPassword))
            throw new ArgumentException("Mật khẩu mới không được để trống");

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