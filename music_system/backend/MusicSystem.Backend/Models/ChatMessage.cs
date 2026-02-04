using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace MusicSystem.Backend.Models
{
    public class ChatMessage
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string? Id { get; set; }

        [BsonElement("senderId")]
        public string SenderId { get; set; } = string.Empty;

        [BsonElement("receiverId")]
        public string ReceiverId { get; set; } = string.Empty;

        [BsonElement("text")]
        public string Text { get; set; } = string.Empty;

        [BsonElement("type")]
        public string Type { get; set; } = "text";

        [BsonElement("mediaUrl")]
        public string? MediaUrl { get; set; }

        [BsonElement("isRead")]
        public bool IsRead { get; set; } = false;

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
