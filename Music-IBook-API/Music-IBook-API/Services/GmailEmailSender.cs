using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;

namespace Music_IBook_API.Services;

public sealed class GmailOptions
{
    public const string SectionName = "Gmail";

    public string Host { get; set; } = "smtp.gmail.com";
    public int Port { get; set; } = 587;
    public string UserName { get; set; } = "";
    public string AppPassword { get; set; } = "";
    public string FromName { get; set; } = "Music IBook";
}

public interface IEmailSender
{
    Task SendPasswordResetOtpAsync(string recipient, string displayName, string otp);
}

public sealed class GmailEmailSender(IOptions<GmailOptions> options) : IEmailSender
{
    private readonly GmailOptions settings = options.Value;

    public async Task SendPasswordResetOtpAsync(
        string recipient,
        string displayName,
        string otp)
    {
        if (string.IsNullOrWhiteSpace(settings.UserName) ||
            string.IsNullOrWhiteSpace(settings.AppPassword))
        {
            throw new InvalidOperationException(
                "Gmail SMTP chưa được cấu hình. Hãy đặt Gmail:UserName và Gmail:AppPassword bằng User Secrets hoặc biến môi trường.");
        }

        var safeName = WebUtility.HtmlEncode(displayName);
        var safeOtp = WebUtility.HtmlEncode(otp);
        using var message = new MailMessage
        {
            From = new MailAddress(settings.UserName.Trim(), settings.FromName),
            Subject = "Mã OTP đặt lại mật khẩu Music IBook",
            Body = $"""
                <div style="font-family:Arial,sans-serif;line-height:1.6;color:#17171f">
                  <h2>Đặt lại mật khẩu Music IBook</h2>
                  <p>Xin chào {safeName},</p>
                  <p>Mã OTP của bạn là:</p>
                  <p style="font-size:30px;font-weight:700;letter-spacing:8px">{safeOtp}</p>
                  <p>Mã có hiệu lực trong 10 phút và chỉ được sử dụng một lần.</p>
                  <p>Nếu bạn không yêu cầu đổi mật khẩu, hãy bỏ qua email này.</p>
                </div>
                """,
            IsBodyHtml = true
        };
        message.To.Add(new MailAddress(recipient));

        using var client = new SmtpClient(settings.Host, settings.Port)
        {
            EnableSsl = true,
            UseDefaultCredentials = false,
            Credentials = new NetworkCredential(
                settings.UserName.Trim(),
                settings.AppPassword.Replace(" ", "", StringComparison.Ordinal))
        };
        await client.SendMailAsync(message);
    }
}
