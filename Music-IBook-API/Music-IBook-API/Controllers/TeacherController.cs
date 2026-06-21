using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        var result = await teacherService.GetDashboardAsync();
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
}
