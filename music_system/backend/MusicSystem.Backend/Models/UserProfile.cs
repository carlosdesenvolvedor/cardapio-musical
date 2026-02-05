using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MusicSystem.Backend.Models;

[Table("user_profiles")]
public class UserProfile
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Required]
    [Column("firebase_uid")]
    [MaxLength(128)]
    public string FirebaseUid { get; set; } = string.Empty;

    [Required]
    [Column("email")]
    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;

    [Required]
    [Column("name")]
    [MaxLength(255)]
    public string Name { get; set; } = string.Empty;

    [Column("role")]
    [MaxLength(50)]
    public string Role { get; set; } = "client"; // client, musician, admin

    [Column("subscription_plan")]
    [MaxLength(50)]
    public string SubscriptionPlan { get; set; } = "free";

    [Column("avatar_url")]
    public string? AvatarUrl { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime? UpdatedAt { get; set; }

    // Expanded Fields matching Flutter App
    [Column("nickname")]
    public string? Nickname { get; set; }

    [Column("search_name")]
    public string? SearchName { get; set; }

    [Column("pix_key")]
    public string? PixKey { get; set; }

    [Column("bio")]
    public string? Bio { get; set; }

    [Column("instagram_url")]
    public string? InstagramUrl { get; set; }

    [Column("youtube_url")]
    public string? YoutubeUrl { get; set; }

    [Column("facebook_url")]
    public string? FacebookUrl { get; set; }

    [Column("gallery_urls", TypeName = "text[]")]
    public List<string>? GalleryUrls { get; set; }

    [Column("fcm_token")]
    public string? FcmToken { get; set; }

    [Column("followers_count")]
    public int FollowersCount { get; set; } = 0;

    [Column("following_count")]
    public int FollowingCount { get; set; } = 0;

    [Column("unread_messages_count")]
    public int UnreadMessagesCount { get; set; } = 0;

    [Column("profile_views_count")]
    public int ProfileViewsCount { get; set; } = 0;

    [Column("is_live")]
    public bool IsLive { get; set; } = false;

    [Column("live_until")]
    public DateTime? LiveUntil { get; set; }

    [Column("last_active_at")]
    public DateTime? LastActiveAt { get; set; }

    [Column("birth_date")]
    public DateTime? BirthDate { get; set; }

    [Column("verification_level")]
    public string VerificationLevel { get; set; } = "none";

    [Column("is_parental_consent_granted")]
    public bool IsParentalConsentGranted { get; set; } = false;

    [Column("is_dob_visible")]
    public bool IsDobVisible { get; set; } = true;

    [Column("is_pix_visible")]
    public bool IsPixVisible { get; set; } = true;

    [Column("profile_type")]
    public string? ProfileType { get; set; }

    [Column("sub_type")]
    public string? SubType { get; set; }

    [Column("artist_score")]
    public int? ArtistScore { get; set; }

    [Column("professional_level")]
    public string? ProfessionalLevel { get; set; }

    [Column("min_suggested_cache")]
    public double? MinSuggestedCache { get; set; }

    [Column("max_suggested_cache")]
    public double? MaxSuggestedCache { get; set; }

    [Column("show_professional_badge")]
    public bool ShowProfessionalBadge { get; set; } = true;

    // JSONB for complex objects if needed, or normalized tables. 
    // For now, ScheduledShows can be ignored or added as JSON later if we fully migrate events.
    // [Column("scheduled_shows", TypeName = "jsonb")]
    // public string? ScheduledShowsJson { get; set; }
}
