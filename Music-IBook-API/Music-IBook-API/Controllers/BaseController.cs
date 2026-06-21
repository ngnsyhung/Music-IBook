using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace Music_IBook_API.Controllers;

public class BaseController : ControllerBase
{
    protected long CurrentUserId
    {
        get
        {
            var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return long.Parse(id!);
        }
    }
}