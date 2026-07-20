using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Music_IBook_API.DTOs;
using Music_IBook_API.Services;

namespace Music_IBook_API.Controllers;

[ApiController]
[Route("api/teacher")]
[Authorize(Roles = "Teacher")]
public class TeacherController : BaseController
{
    private readonly ITeacherService teacherService;

    public TeacherController(ITeacherService teacherService)
    {
        this.teacherService = teacherService;
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        var result = await teacherService.GetDashboardAsync(CurrentUserId);
        return Ok(result);
    }

    [HttpGet("students-progress")]
    public async Task<IActionResult> GetStudentsProgress()
    {
        var result = await teacherService.GetStudentsProgressAsync();
        return Ok(result);
    }

    [HttpGet("students/{studentId}/progress")]
    public async Task<IActionResult> GetStudentProgressDetail(long studentId)
    {
        var result = await teacherService.GetStudentProgressDetailAsync(studentId);
        return Ok(result);
    }

    [HttpGet("students/{studentId}/lessons/{lessonId}/analytics")]
    public async Task<IActionResult> GetLessonAnalytics(long studentId, long lessonId)
    {
        var result = await teacherService.GetLessonAnalyticsAsync(studentId, lessonId);
        return Ok(result);
    }

    [HttpPost("assignments")]
    public async Task<IActionResult> CreateAssignment(CreateStudentAssignmentRequest request)
    {
        var result = await teacherService.CreateStudentAssignmentAsync(request);
        return Ok(result);
    }
}
