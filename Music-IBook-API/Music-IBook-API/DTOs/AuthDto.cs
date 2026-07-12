namespace Music_IBook_API.DTOs;

public class RegisterRequest
{
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
    public string Role { get; set; } = "Student";
}

public class LoginRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
}

public class ForgotPasswordRequest
{
    public string Email { get; set; } = "";
}

public class ResetPasswordRequest
{
    public string Token { get; set; } = "";
    public string NewPassword { get; set; } = "";
}

public class AuthResponse
{
    public string AccessToken { get; set; } = "";
    public string Role { get; set; } = "";
    public string FullName { get; set; } = "";
}
public class GoogleLoginRequest
{
    // Token mã hóa do Google trả về cho app Flutter
    public string IdToken { get; set; } = "";
}