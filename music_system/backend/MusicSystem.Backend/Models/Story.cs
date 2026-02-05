using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace MusicSystem.Backend.Models
{
    public class Story
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string? Id { get; set; }

        [BsonElement("authorId")]
        public string AuthorId { get; set; } = string.Empty;

        [BsonElement("authorName")]
        public string AuthorName { get; set; } = string.Empty;

        [BsonElement("authorPhotoUrl")]
        public string? AuthorPhotoUrl { get; set; }

        [BsonElement("mediaUrl")]
        public string MediaUrl { get; set; } = string.Empty;

        [BsonElement("mediaType")]
        public string MediaType { get; set; } = "image";

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("expiresAt")]
        public DateTime ExpiresAt { get; set; }

        [BsonElement("viewers")]
        public List<string> Viewers { get; set; } = new();

        [BsonElement("effects")]
        public StoryEffects? Effects { get; set; }

        [BsonElement("caption")]
        public string? Caption { get; set; }
    }

    public class StoryEffects
    {
        [BsonElement("filterId")]
        public string? FilterId { get; set; }

        [BsonElement("startOffset")]
        public double? StartOffset { get; set; }

        [BsonElement("endOffset")]
        public double? EndOffset { get; set; }
    }
}
