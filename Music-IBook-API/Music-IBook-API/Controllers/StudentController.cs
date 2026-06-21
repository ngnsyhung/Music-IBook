using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Music_IBook_API.DTOs;
using Music_IBook_API.Services;

namespace Music_IBook_API.Controllers;

[ApiController]
[Route("api/student")]
[Authorize(Roles = "Student")]
public class StudentController : BaseController
{
    private readonly IStudentService studentService;

    public StudentController(IStudentService studentService)
    {
        this.studentService = studentService;
    }

    [HttpGet("progress")]
    public async Task<IActionResult> GetProgress()
    {
        var result = await studentService.GetProgressAsync(CurrentUserId);
        return Ok(result);
    }

    [HttpPut("progress/{lessonId}")]
    public async Task<IActionResult> SaveProgress(
        long lessonId,
        SaveProgressRequest request)
    {
        var result = await studentService.SaveProgressAsync(
            CurrentUserId,
            lessonId,
            request);

        return Ok(result);
    }

    [HttpPost("practice")]
    public async Task<IActionResult> SubmitPractice(SubmitPracticeRequest request)
    {
        var result = await studentService.SubmitPracticeAsync(
            CurrentUserId,
            request);

        return Ok(result);
    }

    [HttpGet("practice-history")]
    public async Task<IActionResult> GetPracticeHistory()
    {
        var result = await studentService.GetPracticeHistoryAsync(CurrentUserId);
        return Ok(result);
    }
}