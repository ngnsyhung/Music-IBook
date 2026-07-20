using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Music_IBook_API.Models;
using System.Net.Http.Json;
using Xunit;

namespace Music_IBook_API.Tests.Controllers;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<MusicIBookDbContext>));

            if (descriptor != null)
            {
                services.Remove(descriptor);
            }

            services.AddDbContext<MusicIBookDbContext>(options =>
            {
                options.UseInMemoryDatabase("InMemoryDbForTesting");
            });

            // Seed Data for tests
            var sp = services.BuildServiceProvider();
            using var scope = sp.CreateScope();
            var scopedServices = scope.ServiceProvider;
            var db = scopedServices.GetRequiredService<MusicIBookDbContext>();
            db.Database.EnsureCreated();

            // Insert mock user
            if (!db.Users.Any())
            {
                db.Users.Add(new AppUser { Id = 1, FullName = "Test Student", Email = "student@test.com", Role = "Student", PasswordHash = "hash", AuthProvider = "Local" });
                db.Lessons.Add(new MusicLesson { Id = 1, TeacherId = 1, Title = "Test Lesson", Composer = "Test", Clef = "G", KeySignature = "C", TimeSignature = "4/4", TimeSignatureMap = "[]", TempoMap = "[]", Tempo = 100, CreatedAtUtc = DateTime.UtcNow, IsPublished = true });
                db.SaveChanges();
            }
        });
    }
}

public class StudentControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public StudentControllerTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetProgress_WithoutAuth_ReturnsUnauthorized()
    {
        // Act
        var response = await _client.GetAsync("/api/student/progress");

        // Assert
        Assert.Equal(System.Net.HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
