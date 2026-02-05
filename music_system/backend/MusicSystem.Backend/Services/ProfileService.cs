using Microsoft.EntityFrameworkCore;
using MusicSystem.Backend.Data;
using MusicSystem.Backend.Models;

namespace MusicSystem.Backend.Services;

public class ProfileService : IProfileService
{
    private readonly AppDbContext _context;

    public ProfileService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<UserProfile?> GetProfileByFirebaseUidAsync(string firebaseUid)
    {
        return await _context.UserProfiles
            .FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);
    }

    public async Task<UserProfile> CreateProfileAsync(UserProfile profile)
    {
        _context.UserProfiles.Add(profile);
        await _context.SaveChangesAsync();
        return profile;
    }

    public async Task<UserProfile?> UpdateProfileAsync(int id, UserProfile profileData)
    {
        var profile = await _context.UserProfiles.FindAsync(id);
        if (profile == null) return null;

        profile.Name = profileData.Name;
        profile.AvatarUrl = profileData.AvatarUrl;
        profile.Role = profileData.Role;
        profile.SubscriptionPlan = profileData.SubscriptionPlan;
        
        // Expanded fields
        profile.Nickname = profileData.Nickname;
        profile.Bio = profileData.Bio;
        profile.InstagramUrl = profileData.InstagramUrl;
        profile.YoutubeUrl = profileData.YoutubeUrl;
        profile.FacebookUrl = profileData.FacebookUrl;
        profile.GalleryUrls = profileData.GalleryUrls;
        profile.FcmToken = profileData.FcmToken;
        profile.BirthDate = profileData.BirthDate;
        profile.PixKey = profileData.PixKey;
        profile.ProfileType = profileData.ProfileType;
        profile.SubType = profileData.SubType;
        profile.MinSuggestedCache = profileData.MinSuggestedCache;
        profile.MaxSuggestedCache = profileData.MaxSuggestedCache;
        
        profile.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return profile;
    }
}
