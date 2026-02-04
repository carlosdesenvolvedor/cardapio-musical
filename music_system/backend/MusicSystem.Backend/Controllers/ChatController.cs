using Microsoft.AspNetCore.Mvc;
using MusicSystem.Backend.Models;
using MusicSystem.Backend.Services;

namespace MusicSystem.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatController : ControllerBase
    {
        private readonly IChatService _chatService;

        public ChatController(IChatService chatService)
        {
            _chatService = chatService;
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory(string userId1, string userId2, int limit = 50)
        {
            var messages = await _chatService.GetMessagesAsync(userId1, userId2, limit);
            return Ok(messages);
        }

        [HttpPost("send")]
        public async Task<IActionResult> SaveMessage([FromBody] ChatMessage message)
        {
            await _chatService.SaveMessageAsync(message);
            return Ok(message);
        }

        [HttpPost("markRead")]
        public async Task<IActionResult> MarkRead([FromBody] MarkReadRequest request)
        {
            await _chatService.MarkAsReadAsync(request.ChatId, request.UserId);
            return Ok();
        }
    }

    public record MarkReadRequest(string ChatId, string UserId);
}
