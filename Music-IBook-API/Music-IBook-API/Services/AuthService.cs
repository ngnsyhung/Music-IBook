using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Music_IBook_API.DTOs;
using Music_IBook_API.Helpers;
using Music_IBook_API.Models;
using Music_IBook_API.Repositories;

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
    private readonly IEmailSender emailSender;

    public AuthService(
        IRepository<AppUser> userRepo,
        IRepository<PasswordResetToken> tokenRepo,
        JwtHelper jwt,
        IConfiguration config,
        IEmailSender emailSender)
    {
        this.userRepo = userRepo;
        this.tokenRepo = tokenRepo;
        this.jwt = jwt;
        this.config = config;
        this.emailSender = emailSender;
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

        if (user == null ||
            string.IsNullOrWhiteSpace(user.PasswordHash) ||
            !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Email hoặc mật khẩu không đúng");

        return new AuthResponse
        {
            AccessToken = jwt.GenerateToken(user),
            FullName = user.FullName,
            Role = user.Role
        };
    }

    public async Task<AuthResponse> UpdateProfileAsync(UpdateProfileRequest request, long userId)
    {
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (string.IsNullOrWhiteSpace(request.FullName))
            throw new ArgumentException("Họ và tên không được để trống");

        var user = await userRepo.GetByIdAsync(userId);
        if (user == null)
            throw new Exception("Không tìm thấy người dùng");

        user.FullName = request.FullName.Trim();

        if (!string.IsNullOrWhiteSpace(request.NewPassword))
        {
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        }

        userRepo.Update(user);
        await userRepo.SaveChangesAsync();

        return new AuthResponse
        {
            AccessToken = jwt.GenerateToken(user),
            FullName = user.FullName,
            Role = user.Role
        };
    }

    public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ArgumentException("Email không được để trống");

        if (!IsValidEmail(request.Email))
            throw new ArgumentException("Email không hợp lệ");

        var email = request.Email.Trim();
        var user = await userRepo.FirstOrDefaultAsync(x => x.Email == email);
        // Luôn trả cùng một phản hồi để không làm lộ email nào đã đăng ký.
        if (user == null) return;

        var otp = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        var now = DateTime.UtcNow;
        var oldTokens = (await tokenRepo.GetAllAsync())
            .Where(x => x.UserId == user.Id && !x.IsUsed)
            .ToList();
        foreach (var oldToken in oldTokens)
        {
            oldToken.IsUsed = true;
            tokenRepo.Update(oldToken);
        }

        var resetToken = new PasswordResetToken
        {
            UserId = user.Id,
            Token = HashOtp(user.Id, otp),
            ExpiresAtUtc = now.AddMinutes(10),
            IsUsed = false
        };

        await tokenRepo.AddAsync(resetToken);
        await tokenRepo.SaveChangesAsync();
        try
        {
            await emailSender.SendPasswordResetOtpAsync(
                user.Email,
                user.FullName,
                otp);
        }
        catch
        {
            resetToken.IsUsed = true;
            tokenRepo.Update(resetToken);
            await tokenRepo.SaveChangesAsync();
            throw;
        }
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        if (request == null)
            throw new ArgumentNullException(nameof(request));

        if (!IsValidEmail(request.Email))
            throw new ArgumentException("Email không hợp lệ");

        var otp = request.Otp.Trim();
        if (!Regex.IsMatch(otp, "^[0-9]{6}$"))
            throw new ArgumentException("OTP phải gồm đúng 6 chữ số");

        if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 8)
            throw new ArgumentException("Mật khẩu mới phải có ít nhất 8 ký tự");

        var user = await userRepo.FirstOrDefaultAsync(x => x.Email == request.Email.Trim());
        if (user == null)
            throw new Exception("OTP không hợp lệ hoặc đã hết hạn");

        var otpHash = HashOtp(user.Id, otp);

        var token = await tokenRepo.FirstOrDefaultAsync(x =>
            x.UserId == user.Id &&
            x.Token == otpHash &&
            !x.IsUsed &&
            x.ExpiresAtUtc > DateTime.UtcNow);

        if (token == null)
            throw new Exception("OTP không hợp lệ hoặc đã hết hạn");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        user.AuthProvider = "Local";
        user.ProviderKey = null;
        token.IsUsed = true;

        userRepo.Update(user);
        tokenRepo.Update(token);

        await userRepo.SaveChangesAsync();
    }

    private string HashOtp(long userId, string otp)
    {
        var secret = config["PasswordReset:HashKey"] ?? config["Jwt:Key"];
        if (string.IsNullOrWhiteSpace(secret))
            throw new InvalidOperationException("Chưa cấu hình khóa băm OTP.");
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(
            hmac.ComputeHash(Encoding.UTF8.GetBytes($"{userId}:{otp}")));
    }
}
