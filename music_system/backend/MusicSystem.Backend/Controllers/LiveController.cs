using Microsoft.AspNetCore.Mvc;
using Livekit.Server.Sdk.Dotnet;

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
            // Usando a API fluente oficial do pacote Livekit.Server.Sdk.Dotnet
            var tokenGenerator = new AccessToken(apiKey, apiSecret)
                .WithIdentity(request.ParticipantName)
                .WithName(request.ParticipantName)
                .WithGrants(new VideoGrants { RoomJoin = true, Room = request.RoomName });

            var token = tokenGenerator.ToJwt();

            return Ok(new
            {
                token = token,
                serverUrl = serverUrl
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[CRITICAL] Error generating token: {ex}");
            return StatusCode(500, $"Error generating token: {ex.Message}");
        }
    }
}

public class TokenRequest
{
    public string RoomName { get; set; } = string.Empty;
    public string ParticipantName { get; set; } = string.Empty;
}
