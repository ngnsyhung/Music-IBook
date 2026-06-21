using Music_IBook_API.DTOs;
using Music_IBook_API.Models;

namespace Music_IBook_API.Services;

public interface ITeacherService
{
    Task<TeacherDashboardDto> GetDashboardAsync();
    Task<List<StudentProgressOverviewDto>> GetStudentsProgressAsync();
    Task<StudentDetailProgressDto> GetStudentProgressDetailAsync(long studentId);
}
