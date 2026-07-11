using Music_IBook_API.DTOs;
using Music_IBook_API.Helpers;
using Music_IBook_API.Models;
using Music_IBook_API.Repositories;
using Google.Apis.Auth;

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

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new Exception("Email hoặc mật khẩu không đúng");

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

    public async Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request)
    {
        try
        {
            var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken);
            
            var user = await userRepo.FirstOrDefaultAsync(x => x.Email == payload.Email);
            
            if (user == null)
            {
                // Register new user via Google
                user = new AppUser
                {
                    FullName = payload.Name,
                    Email = payload.Email,
                    Role = request.Role, // Default or passed from frontend
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()) // random pass
                };
                await userRepo.AddAsync(user);
                await userRepo.SaveChangesAsync();
            }

            return new AuthResponse
            {
                AccessToken = jwt.GenerateToken(user),
                FullName = user.FullName,
                Role = user.Role
            };
        }
        catch (InvalidJwtException)
        {
            throw new Exception("Google token không hợp lệ");
        }
    }

    public async Task<AuthResponse> UpdateProfileAsync(int userId, UpdateProfileRequest request)
    {
        var user = await userRepo.GetByIdAsync(userId);
        if (user == null)
            throw new Exception("Không tìm thấy người dùng");

        user.FullName = request.FullName;
        
        if (!string.IsNullOrEmpty(request.NewPassword))
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
}