using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services;

public interface IProfileService
{
    Task<UserProfile?> GetProfileByFirebaseUidAsync(string firebaseUid);
    Task<UserProfile> CreateProfileAsync(UserProfile profile);
    Task<UserProfile?> UpdateProfileAsync(int id, UserProfile profile);
}
