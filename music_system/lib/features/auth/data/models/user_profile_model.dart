import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.artisticName,
    required super.pixKey,
    super.photoUrl,
    super.bio,
    super.instagramUrl,
    super.youtubeUrl,
    super.facebookUrl,
    super.galleryUrls,
    super.fcmToken,
    super.followersCount = 0,
    super.followingCount = 0,
    super.profileViewsCount = 0,
    super.isLive = false,
    super.liveUntil,
    super.scheduledShow,
    super.lastActiveAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String id) {
    return UserProfileModel(
      id: id,
      email: json['email'] ?? '',
      artisticName: _getName(json),
      pixKey: json['pixKey'] ?? '',
      photoUrl: json['photoUrl'],
      bio: json['bio'],
      instagramUrl: json['instagramUrl'],
      youtubeUrl: json['youtubeUrl'],
      facebookUrl: json['facebookUrl'],
      galleryUrls: json['galleryUrls'] != null
          ? List<String>.from(json['galleryUrls'])
          : null,
      fcmToken: json['fcmToken'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      profileViewsCount: json['profileViewsCount'] ?? 0,
      isLive: json['isLive'] ?? false,
      liveUntil: json['liveUntil'] != null
          ? (json['liveUntil'] as Timestamp).toDate()
          : null,
      scheduledShow: json['scheduledShow'] != null
          ? (json['scheduledShow'] as Timestamp).toDate()
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? (json['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }

  static String _getName(Map<String, dynamic> json) {
    final candidates = ['artisticName', 'name', 'displayName', 'username'];
    for (final key in candidates) {
      final val = json[key];
      if (val != null && val is String && val.trim().isNotEmpty) {
        return val;
      }
    }
    return 'Artista Sem Nome';
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'artisticName': artisticName,
      'pixKey': pixKey,
      'photoUrl': photoUrl,
      'bio': bio,
      'instagramUrl': instagramUrl,
      'youtubeUrl': youtubeUrl,
      'facebookUrl': facebookUrl,
      'galleryUrls': galleryUrls,
      'fcmToken': fcmToken,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'profileViewsCount': profileViewsCount,
      'isLive': isLive,
      'liveUntil': liveUntil != null ? Timestamp.fromDate(liveUntil!) : null,
      'scheduledShow':
          scheduledShow != null ? Timestamp.fromDate(scheduledShow!) : null,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }
}
