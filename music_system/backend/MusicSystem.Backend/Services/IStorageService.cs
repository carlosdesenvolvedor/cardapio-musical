using Microsoft.AspNetCore.Http;

namespace MusicSystem.Backend.Services
{
    public interface IStorageService
    {
        Task<string> UploadFileAsync(IFormFile file, string folderName);
        Task<Stream> GetFileAsync(string fileName);
        Task DeleteFileAsync(string fileName);

        // Multipart Upload Support
        Task<string> InitiateMultipartUploadAsync(string fileName, string folderName);
        Task<string> UploadPartAsync(string key, string uploadId, int partNumber, Stream inputStream);
        Task<bool> CompleteMultipartUploadAsync(string key, string uploadId, List<MusicSystem.Backend.Models.PartETagInfo> parts);

        // Streaming / Presigned Auth
        Task<string> GetPresignedUrlAsync(string fileName, int expiryMinutes = 60);


    }
}
