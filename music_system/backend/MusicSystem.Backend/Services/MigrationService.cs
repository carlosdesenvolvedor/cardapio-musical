using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services;

public class MigrationService : IMigrationService
{
    private readonly IProfileService _profileService;
    private readonly IConfiguration _configuration;
    private readonly FirestoreDb _firestoreDb;

    public MigrationService(IProfileService profileService, IConfiguration configuration)
    {
        _profileService = profileService;
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
}
