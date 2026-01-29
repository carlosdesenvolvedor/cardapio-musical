using Microsoft.AspNetCore.Mvc;
using Livekit.Server.Sdk.Dotnet;
using Livekit.Proto;

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
        if (string.IsNullOrEmpty(request.RoomName) || string.IsNullOrEmpty(request.ParticipantName))
        {
            return BadRequest("RoomName and ParticipantName are required.");
        }

        // In a real scenario, these should come from appsettings.json or Environment Variables
        // For development/initial setup as per docker-compose:
        var apiKey = _configuration["LiveKit:ApiKey"] ?? "devkey";
        var apiSecret = _configuration["LiveKit:ApiSecret"] ?? "secret";
        var serverUrl = _configuration["LiveKit:ServerUrl"] ?? "http://localhost:7880";

        try
        {
            var tokenGenerator = new AccessToken(apiKey, apiSecret);
            // Em algumas versões do SDK as propriedades são Identity e Name
            // Verificando os erros, o compilador não as encontrou. 
            // Vamos usar os métodos ou propriedades corretas baseados no SDK .NET
            
            tokenGenerator.SetIdentity(request.ParticipantName);
            tokenGenerator.SetName(request.ParticipantName);
            
            var videoGrant = new VideoGrant
            {
                RoomJoin = true,
                Room = request.RoomName
            };
            
            tokenGenerator.AddGrant(videoGrant);

            var token = tokenGenerator.ToJwt();

            return Ok(new
            {
                token = token,
                serverUrl = serverUrl
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Error generating token: {ex.Message}");
        }
    }
}

public class TokenRequest
{
    public string RoomName { get; set; } = string.Empty;
    public string ParticipantName { get; set; } = string.Empty;
}
