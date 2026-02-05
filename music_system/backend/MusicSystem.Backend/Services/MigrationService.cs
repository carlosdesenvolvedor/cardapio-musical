using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services;

public class MigrationService : IMigrationService
{
    private readonly IProfileService _profileService;
    private readonly IFeedService _feedService;
    private readonly IConfiguration _configuration;
    private readonly FirestoreDb _firestoreDb;

    public MigrationService(IProfileService profileService, IFeedService feedService, IConfiguration configuration)
    {
        _profileService = profileService;
        _feedService = feedService;
        _configuration = configuration;

        var credentialPath = configuration["Firebase:CredentialPath"] ?? "serviceAccountKey.json";

        // Ensure Firebase App is initialized
        if (FirebaseApp.DefaultInstance == null)
        {
             if (File.Exists(credentialPath))
             {
                 try {
                    FirebaseApp.Create(new AppOptions()
                    {
                        Credential = GoogleCredential.FromFile(credentialPath)
                    });
                 } catch (Exception ex) {
                    Console.WriteLine($"Error initializing Firebase: {ex.Message}");
                 }
             }
        }
        
        // Assuming projectId is available 
        var projectId = configuration["Firebase:ProjectId"] ?? "music-system-421ee";
        
        if (File.Exists(credentialPath))
        {
            _firestoreDb = new FirestoreDbBuilder
            {
                ProjectId = projectId,
                Credential = GoogleCredential.FromFile(credentialPath)
            }.Build();
        }
        else
        {
            _firestoreDb = FirestoreDb.Create(projectId);
        }
    }

    public async Task<int> MigrateUsersFromFirestoreAsync()
    {
        var usersRef = _firestoreDb.Collection("users");
        var snapshot = await usersRef.GetSnapshotAsync();
        int count = 0;

        foreach (var document in snapshot.Documents)
        {
            if (document.Exists)
            {
                var dict = document.ToDictionary();
                var uid = document.Id;
                var email = dict.ContainsKey("email") ? dict["email"]?.ToString() : "";
                var name = dict.ContainsKey("name") ? dict["name"]?.ToString() : "";
                var role = dict.ContainsKey("role") ? dict["role"]?.ToString() : "client";
                var photoUrl = dict.ContainsKey("photoUrl") ? dict["photoUrl"]?.ToString() : null;

                if (string.IsNullOrEmpty(email)) continue; // Skip invalid users

                var existing = await _profileService.GetProfileByFirebaseUidAsync(uid);
                if (existing == null)
                {
                    var newProfile = new UserProfile
                    {
                        FirebaseUid = uid,
                        Email = email!,
                        Name = name ?? "Unknown",
                        Role = role ?? "client",
                        AvatarUrl = photoUrl,
                        CreatedAt = DateTime.UtcNow // Firestore might have createdAt
                    };
                    await _profileService.CreateProfileAsync(newProfile);
                    count++;
                }
            }
        }
        return count;
    }

    public async Task<int> MigratePostsFromFirestoreAsync()
    {
        var postsRef = _firestoreDb.Collection("posts");
        var snapshot = await postsRef.GetSnapshotAsync();
        int count = 0;

        foreach (var document in snapshot.Documents)
        {
            if (document.Exists)
            {
                var dict = document.ToDictionary();
                
                var post = new Post
                {
                    AuthorId = dict.ContainsKey("authorId") ? dict["authorId"]?.ToString() ?? "" : "",
                    AuthorName = dict.ContainsKey("authorName") ? dict["authorName"]?.ToString() ?? "" : "",
                    AuthorPhotoUrl = dict.ContainsKey("authorPhotoUrl") ? dict["authorPhotoUrl"]?.ToString() : null,
                    ImageUrl = dict.ContainsKey("imageUrl") ? dict["imageUrl"]?.ToString() ?? "" : "",
                    Caption = dict.ContainsKey("caption") ? dict["caption"]?.ToString() ?? "" : "",
                    PostType = dict.ContainsKey("postType") ? dict["postType"]?.ToString() ?? "image" : "image",
                    CreatedAt = dict.ContainsKey("createdAt") && dict["createdAt"] is Timestamp ts ? ts.ToDateTime() : DateTime.UtcNow
                };

                if (dict.ContainsKey("mediaUrls") && dict["mediaUrls"] is List<object> mediaList)
                {
                    post.MediaUrls = mediaList.Select(m => m.ToString() ?? "").ToList();
                }

                if (dict.ContainsKey("likes") && dict["likes"] is List<object> likesList)
                {
                    post.Likes = likesList.Select(l => l.ToString() ?? "").ToList();
                }

                if (dict.ContainsKey("taggedUserIds") && dict["taggedUserIds"] is List<object> taggedList)
                {
                    post.TaggedUserIds = taggedList.Select(t => t.ToString() ?? "").ToList();
                }

                await _feedService.CreatePostAsync(post);
                count++;
            }
        }
        return count;
    }

    public async Task<int> MigrateStoriesFromFirestoreAsync()
    {
        var storiesRef = _firestoreDb.Collection("stories");
        var snapshot = await storiesRef.GetSnapshotAsync();
        int count = 0;

        foreach (var document in snapshot.Documents)
        {
            if (document.Exists)
            {
                var dict = document.ToDictionary();
                
                var story = new Story
                {
                    AuthorId = dict.ContainsKey("authorId") ? dict["authorId"]?.ToString() ?? "" : "",
                    AuthorName = dict.ContainsKey("authorName") ? dict["authorName"]?.ToString() ?? "" : "",
                    AuthorPhotoUrl = dict.ContainsKey("authorPhotoUrl") ? dict["authorPhotoUrl"]?.ToString() : null,
                    MediaUrl = dict.ContainsKey("mediaUrl") ? dict["mediaUrl"]?.ToString() ?? "" : "",
                    MediaType = dict.ContainsKey("mediaType") ? dict["mediaType"]?.ToString() ?? "image" : "image",
                    Caption = dict.ContainsKey("caption") ? dict["caption"]?.ToString() : null,
                    CreatedAt = dict.ContainsKey("createdAt") && dict["createdAt"] is Timestamp ts ? ts.ToDateTime() : DateTime.UtcNow,
                    ExpiresAt = dict.ContainsKey("expiresAt") && dict["expiresAt"] is Timestamp expTs ? expTs.ToDateTime() : DateTime.UtcNow.AddHours(24)
                };

                if (dict.ContainsKey("viewers") && dict["viewers"] is List<object> viewersList)
                {
                    story.Viewers = viewersList.Select(v => v.ToString() ?? "").ToList();
                }

                // Handling Effects if they exist
                if (dict.ContainsKey("effects") && dict["effects"] is Dictionary<string, object> effectsDict)
                {
                    story.Effects = new StoryEffects
                    {
                        FilterId = effectsDict.ContainsKey("filterId") ? effectsDict["filterId"]?.ToString() : null,
                        StartOffset = effectsDict.ContainsKey("startOffset") ? Convert.ToDouble(effectsDict["startOffset"]) : null,
                        EndOffset = effectsDict.ContainsKey("endOffset") ? Convert.ToDouble(effectsDict["endOffset"]) : null
                    };
                }

                await _feedService.CreateStoryAsync(story);
                count++;
            }
        }
        return count;
    }
}
