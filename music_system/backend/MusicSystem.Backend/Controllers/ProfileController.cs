using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MusicSystem.Backend.Models;
using MusicSystem.Backend.Services;
using System.Security.Claims;

namespace MusicSystem.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Requires Firebase JWT
public class ProfileController : ControllerBase
{
    private readonly IProfileService _profileService;

    public ProfileController(IProfileService profileService)
    {
        _profileService = profileService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile()
    {
        var firebaseUid = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(firebaseUid))
        {
            return Unauthorized("User ID not found in token.");
        }

        var profile = await _profileService.GetProfileByFirebaseUidAsync(firebaseUid);
        if (profile == null)
        {
            return NotFound("Profile not found.");
        }

        return Ok(profile);
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrUpdateProfile([FromBody] UserProfile profileData)
    {
        var firebaseUid = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(firebaseUid))
        {
            return Unauthorized("User ID not found in token.");
        }

        if (profileData.FirebaseUid != firebaseUid)
        {
            return BadRequest("Profile UID does not match token UID.");
        }

        // Check if exists
        var existingProfile = await _profileService.GetProfileByFirebaseUidAsync(firebaseUid);
        if (existingProfile == null)
        {
            var newProfile = await _profileService.CreateProfileAsync(profileData);
            return CreatedAtAction(nameof(GetMyProfile), new { id = newProfile.Id }, newProfile);
        }
        else
        {
            var updatedProfile = await _profileService.UpdateProfileAsync(existingProfile.Id, profileData);
            return Ok(updatedProfile);
        }
    }
}
