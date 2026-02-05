using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MusicSystem.Backend.Services;

namespace MusicSystem.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
// [Authorize(Roles = "admin")]
[AllowAnonymous]
public class MigrationController : ControllerBase
{
    private readonly IMigrationService _migrationService;

    public MigrationController(IMigrationService migrationService)
    {
        _migrationService = migrationService;
    }

    [HttpPost("users")]
    public async Task<IActionResult> MigrateUsers()
    {
        try
        {
            var count = await _migrationService.MigrateUsersFromFirestoreAsync();
            return Ok(new { message = $"Migration completed. {count} users migrated." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpPost("posts")]
    public async Task<IActionResult> MigratePosts()
    {
        try
        {
            var count = await _migrationService.MigratePostsFromFirestoreAsync();
            return Ok(new { message = $"Migration completed. {count} posts migrated." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpPost("stories")]
    public async Task<IActionResult> MigrateStories()
    {
        try
        {
            var count = await _migrationService.MigrateStoriesFromFirestoreAsync();
            return Ok(new { message = $"Migration completed. {count} stories migrated." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }
}
