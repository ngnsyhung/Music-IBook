using Microsoft.Extensions.Configuration;
using Moq;
using Music_IBook_API.DTOs;
using Music_IBook_API.Helpers;
using Music_IBook_API.Models;
using Music_IBook_API.Repositories;
using Music_IBook_API.Services;
using System.Linq.Expressions;
using Xunit;

namespace Music_IBook_API.Tests.Services;

public class AuthServiceTests
{
    private readonly Mock<IRepository<AppUser>> _mockUserRepo;
    private readonly Mock<IRepository<PasswordResetToken>> _mockTokenRepo;
    private readonly Mock<IEmailSender> _mockEmailSender;
    private readonly AuthService _authService;

    public AuthServiceTests()
    {
        _mockUserRepo = new Mock<IRepository<AppUser>>();
        _mockTokenRepo = new Mock<IRepository<PasswordResetToken>>();
        _mockEmailSender = new Mock<IEmailSender>();

        var inMemorySettings = new Dictionary<string, string?> {
            {"Jwt:Key", "SuperSecretKeyThatIsAtLeast32BytesLongForSHA256"},
            {"Jwt:Issuer", "TestIssuer"},
            {"Jwt:Audience", "TestAudience"}
        };

        IConfiguration configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        var jwtHelper = new JwtHelper(configuration);

        _authService = new AuthService(
            _mockUserRepo.Object,
            _mockTokenRepo.Object,
            jwtHelper,
            configuration,
            _mockEmailSender.Object
        );
    }

    [Fact]
    public async Task RegisterAsync_ValidRequest_CreatesUserAndReturnsToken()
    {
        // Arrange
        var request = new RegisterRequest
        {
            Email = "test@student.com",
            Password = "Password123!",
            FullName = "Test Student",
            Role = "Student"
        };

        _mockUserRepo.Setup(x => x.FirstOrDefaultAsync(It.IsAny<Expression<Func<AppUser, bool>>>()))
            .ReturnsAsync((AppUser?)null);

        _mockUserRepo.Setup(x => x.AddAsync(It.IsAny<AppUser>()))
            .Callback<AppUser>(user => user.Id = 1)
            .Returns(Task.CompletedTask);

        // Act
        var result = await _authService.RegisterAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.AccessToken);
        Assert.Equal("Test Student", result.FullName);
        Assert.Equal("Student", result.Role);
        _mockUserRepo.Verify(x => x.AddAsync(It.IsAny<AppUser>()), Times.Once);
        _mockUserRepo.Verify(x => x.SaveChangesAsync(), Times.Once);
    }

    [Fact]
    public async Task RegisterAsync_ExistingEmail_ThrowsException()
    {
        // Arrange
        var request = new RegisterRequest
        {
            Email = "existing@student.com",
            Password = "Password123!",
            FullName = "Test Student",
            Role = "Student"
        };

        _mockUserRepo.Setup(x => x.FirstOrDefaultAsync(It.IsAny<Expression<Func<AppUser, bool>>>()))
            .ReturnsAsync(new AppUser { Email = "existing@student.com" });

        // Act & Assert
        var ex = await Assert.ThrowsAsync<Exception>(() => _authService.RegisterAsync(request));
        Assert.Equal("Email đã tồn tại", ex.Message);
    }

    [Fact]
    public async Task LoginAsync_ValidCredentials_ReturnsToken()
    {
        // Arrange
        var password = "Password123!";
        var user = new AppUser
        {
            Id = 1,
            Email = "test@student.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            FullName = "Test Student",
            Role = "Student"
        };

        var request = new LoginRequest
        {
            Email = "test@student.com",
            Password = password
        };

        _mockUserRepo.Setup(x => x.FirstOrDefaultAsync(It.IsAny<Expression<Func<AppUser, bool>>>()))
            .ReturnsAsync(user);

        // Act
        var result = await _authService.LoginAsync(request);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.AccessToken);
        Assert.Equal("Test Student", result.FullName);
    }

    [Fact]
    public async Task LoginAsync_InvalidPassword_ThrowsException()
    {
        // Arrange
        var user = new AppUser
        {
            Id = 1,
            Email = "test@student.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Password123!"),
            FullName = "Test Student",
            Role = "Student"
        };

        var request = new LoginRequest
        {
            Email = "test@student.com",
            Password = "WrongPassword!"
        };

        _mockUserRepo.Setup(x => x.FirstOrDefaultAsync(It.IsAny<Expression<Func<AppUser, bool>>>()))
            .ReturnsAsync(user);

        // Act & Assert
        var ex = await Assert.ThrowsAsync<UnauthorizedAccessException>(() => _authService.LoginAsync(request));
        Assert.Equal("Email hoặc mật khẩu không đúng", ex.Message);
    }
}
