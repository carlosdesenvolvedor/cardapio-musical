using MongoDB.Driver;
using MusicSystem.Backend.Models;
using Microsoft.Extensions.Configuration;

namespace MusicSystem.Backend.Services
{
    public class MongoChatService : IChatService
    {
        private readonly IMongoCollection<ChatMessage> _messages;

        public MongoChatService(IConfiguration config)
        {
            var client = new MongoClient(config.GetConnectionString("MongoDb"));
            var database = client.GetDatabase("MusicSystem");
            _messages = database.GetCollection<ChatMessage>("Messages");
        }

        public async Task<List<ChatMessage>> GetMessagesAsync(string userId1, string userId2, int limit = 50)
        {
            // Implementation of logical "OR" for both ways of the conversation
            var filter = Builders<ChatMessage>.Filter.And(
                Builders<ChatMessage>.Filter.Or(
                    Builders<ChatMessage>.Filter.And(
                        Builders<ChatMessage>.Filter.Eq(m => m.SenderId, userId1),
                        Builders<ChatMessage>.Filter.Eq(m => m.ReceiverId, userId2)
                    ),
                    Builders<ChatMessage>.Filter.And(
                        Builders<ChatMessage>.Filter.Eq(m => m.SenderId, userId2),
                        Builders<ChatMessage>.Filter.Eq(m => m.ReceiverId, userId1)
                    )
                )
            );

            return await _messages.Find(filter)
                .SortByDescending(m => m.CreatedAt)
                .Limit(limit)
                .ToListAsync();
        }

        public async Task SaveMessageAsync(ChatMessage message)
        {
            await _messages.InsertOneAsync(message);
        }

        public async Task MarkAsReadAsync(string chatId, string userId)
        {
            // Simple approach for marking messages as read for a specific recipient
            var filter = Builders<ChatMessage>.Filter.And(
                Builders<ChatMessage>.Filter.Eq(m => m.ReceiverId, userId),
                Builders<ChatMessage>.Filter.Eq(m => m.IsRead, false)
            );
            
            var update = Builders<ChatMessage>.Update.Set(m => m.IsRead, true);
            await _messages.UpdateManyAsync(filter, update);
        }
    }
}
