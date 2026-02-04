using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services
{
    public interface IChatService
    {
        Task<List<ChatMessage>> GetMessagesAsync(string userId1, string userId2, int limit = 50);
        Task SaveMessageAsync(ChatMessage message);
        Task MarkAsReadAsync(string chatId, string userId);
    }
}
