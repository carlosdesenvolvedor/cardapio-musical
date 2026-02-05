using MongoDB.Driver;
using MusicSystem.Backend.Models;
using Microsoft.Extensions.Configuration;
using MongoDB.Bson;

namespace MusicSystem.Backend.Services
{
    public class MongoFeedService : IFeedService
    {
        private readonly IMongoCollection<Post> _posts;
        private readonly IMongoCollection<Story> _stories;

        public MongoFeedService(IConfiguration config)
        {
            var client = new MongoClient(config.GetConnectionString("MongoDb"));
            var database = client.GetDatabase("MusicSystem");
            _posts = database.GetCollection<Post>("Posts");
            _stories = database.GetCollection<Story>("Stories");
        }

        public async Task<List<Post>> GetFeedAsync(int limit = 20, string? lastId = null)
        {
            var filter = Builders<Post>.Filter.Empty;
            
            if (!string.IsNullOrEmpty(lastId))
            {
                // Simple pagination logic if needed, otherwise just sort by date
                // var lastPost = await _posts.Find(p => p.Id == lastId).FirstOrDefaultAsync();
                // if (lastPost != null) filter &= Builders<Post>.Filter.Lt(p => p.CreatedAt, lastPost.CreatedAt);
            }

            return await _posts.Find(filter)
                .SortByDescending(p => p.CreatedAt)
                .Limit(limit)
                .ToListAsync();
        }

        public async Task<List<Post>> GetUserPostsAsync(string userId)
        {
            return await _posts.Find(p => p.AuthorId == userId)
                .SortByDescending(p => p.CreatedAt)
                .ToListAsync();
        }

        public async Task<Post> CreatePostAsync(Post post)
        {
            post.CreatedAt = DateTime.UtcNow;
            await _posts.InsertOneAsync(post);
            return post;
        }

        public async Task<List<Story>> GetActiveStoriesAsync()
        {
            var now = DateTime.UtcNow;
            return await _stories.Find(s => s.ExpiresAt > now)
                .SortByDescending(s => s.CreatedAt)
                .ToListAsync();
        }

        public async Task<Story> CreateStoryAsync(Story story)
        {
            story.CreatedAt = DateTime.UtcNow;
            if (story.ExpiresAt == default)
            {
                story.ExpiresAt = story.CreatedAt.AddHours(24);
            }
            await _stories.InsertOneAsync(story);
            return story;
        }

        public async Task LikePostAsync(string postId, string userId)
        {
            var filter = Builders<Post>.Filter.Eq(p => p.Id, postId);
            var update = Builders<Post>.Update.AddToSet(p => p.Likes, userId);
            await _posts.UpdateOneAsync(filter, update);
        }

        public async Task UnlikePostAsync(string postId, string userId)
        {
            var filter = Builders<Post>.Filter.Eq(p => p.Id, postId);
            var update = Builders<Post>.Update.Pull(p => p.Likes, userId);
            await _posts.UpdateOneAsync(filter, update);
        }
    }
}
