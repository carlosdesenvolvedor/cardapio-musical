using Amazon.S3;
using Amazon.S3.Model;
using Amazon.S3.Transfer;
using Microsoft.Extensions.Configuration;

namespace MusicSystem.Backend.Services
{
    public class MinioStorageService : IStorageService
    {
        private readonly IAmazonS3 _s3Client;
        private readonly string _bucketName;

        public MinioStorageService(IConfiguration configuration)
        {
            var minioConfig = configuration.GetSection("Minio");
            _bucketName = minioConfig["BucketName"] ?? "default-bucket";

            var config = new AmazonS3Config
            {
                ServiceURL = minioConfig["Endpoint"],
                ForcePathStyle = bool.Parse(minioConfig["ForcePathStyle"] ?? "true"),
                UseHttp = true 
            };

            _s3Client = new AmazonS3Client(
                minioConfig["AccessKey"],
                minioConfig["SecretKey"],
                config
            );
        }

        public async Task<string> UploadFileAsync(IFormFile file, string folderName)
        {
            await EnsureBucketExistsAsync();

            var fileExtension = Path.GetExtension(file.FileName);
            var fileName = $"{folderName}/{Guid.NewGuid()}{fileExtension}";

            using var newMemoryStream = new MemoryStream();
            await file.CopyToAsync(newMemoryStream);

            var extension = Path.GetExtension(file.FileName).ToLower();
            var contentType = extension switch
            {
                ".mp4" => "video/mp4",
                ".mov" => "video/quicktime",
                ".jpg" => "image/jpeg",
                ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                _ => "application/octet-stream"
            };

            var uploadRequest = new TransferUtilityUploadRequest
            {
                InputStream = newMemoryStream,
                Key = fileName,
                BucketName = _bucketName,
                CannedACL = S3CannedACL.PublicRead,
                ContentType = contentType
            };

            var fileTransferUtility = new TransferUtility(_s3Client);
            await fileTransferUtility.UploadAsync(uploadRequest);

            // Return only the key (path within the bucket)
            return fileName;
        }
        
        public async Task<Stream> GetFileAsync(string fileName)
        {
             var response = await _s3Client.GetObjectAsync(_bucketName, fileName);
             return response.ResponseStream;
        }

        public async Task DeleteFileAsync(string fileName)
        {
            await _s3Client.DeleteObjectAsync(_bucketName, fileName);
        }

        // Multipart Implementation
        public async Task<string> InitiateMultipartUploadAsync(string fileName, string folderName)
        {
            await EnsureBucketExistsAsync();
            var key = $"{folderName}/{Guid.NewGuid()}{Path.GetExtension(fileName)}";
            
            var extension = Path.GetExtension(fileName).ToLower();
            var contentType = extension switch
            {
                ".mp4" => "video/mp4",
                ".mov" => "video/quicktime",
                ".jpg" => "image/jpeg",
                ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                _ => "application/octet-stream"
            };

            var request = new InitiateMultipartUploadRequest
            {
                BucketName = _bucketName,
                Key = key,
                CannedACL = S3CannedACL.PublicRead,
                ContentType = contentType
            };

            var response = await _s3Client.InitiateMultipartUploadAsync(request);
            // Return 'Key|UploadId' so the client can send both back
            return $"{key}|{response.UploadId}";
        }

        public async Task<string> UploadPartAsync(string key, string uploadId, int partNumber, Stream inputStream)
        {
            var request = new UploadPartRequest
            {
                BucketName = _bucketName,
                Key = key,
                UploadId = uploadId,
                PartNumber = partNumber,
                InputStream = inputStream
            };

            var response = await _s3Client.UploadPartAsync(request);
            return response.ETag;
        }

        public async Task<bool> CompleteMultipartUploadAsync(string key, string uploadId, List<MusicSystem.Backend.Models.PartETagInfo> parts)
        {
            var partETags = parts.Select(p => new PartETag { PartNumber = p.PartNumber, ETag = p.ETag }).ToList();

            var request = new CompleteMultipartUploadRequest
            {
                BucketName = _bucketName,
                Key = key,
                UploadId = uploadId,
                PartETags = partETags
            };

            var response = await _s3Client.CompleteMultipartUploadAsync(request);
            return response.HttpStatusCode == System.Net.HttpStatusCode.OK;
        }

        public async Task<string> GetPresignedUrlAsync(string fileName, int expiryMinutes = 60)
        {
            var request = new GetPreSignedUrlRequest
            {
                BucketName = _bucketName,
                Key = fileName,
                Expires = DateTime.UtcNow.AddMinutes(expiryMinutes),
                Verb = HttpVerb.GET
            };

            var url = _s3Client.GetPreSignedURL(request);
            
            // Extract the part after the bucket name to keep query parameters
            // Minio URL format usually: http://minio:9000/bucket/object?params
            var bucketPrefix = $"/{_bucketName}/";
            var bucketIndex = url.IndexOf(bucketPrefix);
            if (bucketIndex != -1)
            {
                var objectAndParams = url.Substring(bucketIndex + bucketPrefix.Length);
                return $"http://136.248.64.90/media/{objectAndParams}";
            }

            // Fallback: simple replace if the robust one fails
            return url.Replace("http://minio:9000/music-system-media/", "http://136.248.64.90/media/")
                      .Replace("minio:9000", "136.248.64.90/media");
        }

        private async Task EnsureBucketExistsAsync()
        {
            bool bucketExists = await Amazon.S3.Util.AmazonS3Util.DoesS3BucketExistV2Async(_s3Client, _bucketName);
            if (!bucketExists)
            {
                var putBucketRequest = new PutBucketRequest
                {
                    BucketName = _bucketName,
                    UseClientRegion = true
                };
                await _s3Client.PutBucketAsync(putBucketRequest);
            }
        }
    }
}

