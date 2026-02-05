using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace MusicSystem.Backend.Models
{
    public class Post
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

        [BsonElement("imageUrl")]
        public string ImageUrl { get; set; } = string.Empty;

        [BsonElement("mediaUrls")]
        public List<string> MediaUrls { get; set; } = new();

        [BsonElement("postType")]
        public string PostType { get; set; } = "image";

        [BsonElement("caption")]
        public string Caption { get; set; } = string.Empty;

        [BsonElement("likes")]
        public List<string> Likes { get; set; } = new();

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("taggedUserIds")]
        public List<string> TaggedUserIds { get; set; } = new();

        [BsonElement("collaboratorIds")]
        public List<string> CollaboratorIds { get; set; } = new();

        [BsonElement("musicData")]
        public object? MusicData { get; set; }
    }
}
