using Microsoft.AspNetCore.Mvc;
using MusicSystem.Backend.Services;

namespace MusicSystem.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CompleteUploadRequest
    {
        public string Key { get; set; } = string.Empty;
        public string UploadId { get; set; } = string.Empty;
        public List<MusicSystem.Backend.Models.PartETagInfo> Parts { get; set; } = new();
    }

    [ApiController]
    [Route("api/[controller]")]
    public class StorageController : ControllerBase
    {
        private readonly IStorageService _storageService;

        public StorageController(IStorageService storageService)
        {
            _storageService = storageService;
        }

        [HttpPost("upload")]
        [RequestSizeLimit(524288000)] // 500 MB
        public async Task<IActionResult> Upload(IFormFile file, [FromQuery] string folder = "uploads")
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded.");

            try 
            {
                var result = await _storageService.UploadFileAsync(file, folder);
                return Ok(new { Path = result });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost("multipart/start")]
        public async Task<IActionResult> StartMultipartUpload([FromQuery] string fileName, [FromQuery] string folder = "videos")
        {
            try
            {
                var result = await _storageService.InitiateMultipartUploadAsync(fileName, folder);
                var parts = result.Split('|');
                return Ok(new { Key = parts[0], UploadId = parts[1] });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error starting upload: {ex.Message}");
            }
        }

        [HttpPost("multipart/part")]
        [RequestSizeLimit(524288000)] // 500 MB limit per part
        public async Task<IActionResult> UploadPart(IFormFile file, [FromQuery] string key, [FromQuery] string uploadId, [FromQuery] int partNumber)
        {
            try
            {
                using var stream = file.OpenReadStream();
                var etag = await _storageService.UploadPartAsync(key, uploadId, partNumber, stream);
                return Ok(new { ETag = etag });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error uploading part: {ex.Message}");
            }
        }

        [HttpPost("multipart/complete")]
        public async Task<IActionResult> CompleteMultipartUpload([FromBody] CompleteUploadRequest request)
        {
            try
            {
                var success = await _storageService.CompleteMultipartUploadAsync(request.Key, request.UploadId, request.Parts);
                if (success) return Ok(new { Message = "Upload completed successfully", Path = request.Key });
                return BadRequest("Failed to complete upload");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error completing upload: {ex.Message}");
            }
        }

        [HttpGet("stream/{*fileName}")]
        public async Task<IActionResult> StreamFile(string fileName)
        {
            try
            {
                var url = await _storageService.GetPresignedUrlAsync(fileName);
                return Redirect(url);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error generating stream URL: {ex.Message}");
            }
        }
    }
}

