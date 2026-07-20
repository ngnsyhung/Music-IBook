using Music_IBook_API.DTOs;

namespace Music_IBook_API.Services;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request);
    Task<AuthResponse> LoginAsync(LoginRequest request);
    Task ForgotPasswordAsync(ForgotPasswordRequest request);
    Task ResetPasswordAsync(ResetPasswordRequest request);
    Task<AuthResponse> UpdateProfileAsync(UpdateProfileRequest request, long userId);
}
