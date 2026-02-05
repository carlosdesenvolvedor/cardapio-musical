using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MusicSystem.Backend.Models;
using MusicSystem.Backend.Services;
using System.Security.Claims;

namespace MusicSystem.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FeedController : ControllerBase
    {
        private readonly IFeedService _feedService;

        public FeedController(IFeedService feedService)
        {
            _feedService = feedService;
        }

        [HttpGet]
        public async Task<ActionResult<List<Post>>> GetFeed([FromQuery] int limit = 20, [FromQuery] string? lastId = null)
        {
            var posts = await _feedService.GetFeedAsync(limit, lastId);
            return Ok(posts);
        }

        [HttpGet("user/{userId}")]
        public async Task<ActionResult<List<Post>>> GetUserPosts(string userId)
        {
            var posts = await _feedService.GetUserPostsAsync(userId);
            return Ok(posts);
        }

        [HttpPost]
        public async Task<ActionResult<Post>> CreatePost(Post post)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            post.AuthorId = userId;
            // Note: In a real scenario, we'd fetch the name/photo from ProfileService if not provided
            var createdPost = await _feedService.CreatePostAsync(post);
            return CreatedAtAction(nameof(GetFeed), new { id = createdPost.Id }, createdPost);
        }

        [HttpGet("stories")]
        public async Task<ActionResult<List<Story>>> GetStories()
        {
            var stories = await _feedService.GetActiveStoriesAsync();
            return Ok(stories);
        }

        [HttpPost("stories")]
        public async Task<ActionResult<Story>> CreateStory(Story story)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            story.AuthorId = userId;
            var createdStory = await _feedService.CreateStoryAsync(story);
            return Ok(createdStory);
        }

        [HttpPost("like/{postId}")]
        public async Task<IActionResult> LikePost(string postId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            await _feedService.LikePostAsync(postId, userId);
            return Ok();
        }

        [HttpDelete("like/{postId}")]
        public async Task<IActionResult> UnlikePost(string postId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            await _feedService.UnlikePostAsync(postId, userId);
            return Ok();
        }
    }
}
