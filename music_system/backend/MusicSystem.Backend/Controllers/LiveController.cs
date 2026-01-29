using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Collections.Generic;
using System;
using Microsoft.Extensions.Configuration;

namespace MusicSystem.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LiveController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public LiveController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpPost("token")]
    public IActionResult GetToken([FromBody] TokenRequest request)
    {
        Console.WriteLine($"[DEBUG] Token Request: Room={request.RoomName}, Participant={request.ParticipantName}");

        if (string.IsNullOrEmpty(request.RoomName) || string.IsNullOrEmpty(request.ParticipantName))
        {
            Console.WriteLine("[ERROR] Missing RoomName or ParticipantName");
            return BadRequest("RoomName and ParticipantName are required.");
        }

        var apiKey = _configuration["LiveKit:ApiKey"] ?? "devkey";
        var apiSecret = _configuration["LiveKit:ApiSecret"] ?? "secret";
        var serverUrl = _configuration["LiveKit:ServerUrl"] ?? "http://localhost:7880";

        try
        {
            // Manual JWT Generation for LiveKit
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(apiSecret));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var header = new JwtHeader(credentials);
            
            // LiveKit expects video grants object
            var videoGrants = new Dictionary<string, object>
            {
                { "room", request.RoomName },
                { "roomJoin", true }
            };

            var payload = new JwtPayload
            {
                { "iss", apiKey },
                { "sub", request.ParticipantName },
                { "nbf", DateTimeOffset.UtcNow.ToUnixTimeSeconds() },
                { "exp", DateTimeOffset.UtcNow.AddHours(6).ToUnixTimeSeconds() },
                { "name", request.ParticipantName },
                { "video", videoGrants }
            };

            var secToken = new JwtSecurityToken(header, payload);
            var handler = new JwtSecurityTokenHandler();
            var token = handler.WriteToken(secToken);

            return Ok(new
            {
                token = token,
                serverUrl = serverUrl
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[CRITICAL] Error generating token (Manual JWT): {ex}");
            return StatusCode(500, $"Error generating token: {ex.Message}");
        }
    }
}

public class TokenRequest
{
    public string RoomName { get; set; } = string.Empty;
    public string ParticipantName { get; set; } = string.Empty;
}
