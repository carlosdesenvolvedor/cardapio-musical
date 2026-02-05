using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services
{
    public interface IFeedService
    {
        Task<List<Post>> GetFeedAsync(int limit = 20, string? lastId = null);
        Task<List<Post>> GetUserPostsAsync(string userId);
        Task<Post> CreatePostAsync(Post post);
        Task<List<Story>> GetActiveStoriesAsync();
        Task<Story> CreateStoryAsync(Story story);
        Task LikePostAsync(string postId, string userId);
        Task UnlikePostAsync(string postId, string userId);
    }
}
