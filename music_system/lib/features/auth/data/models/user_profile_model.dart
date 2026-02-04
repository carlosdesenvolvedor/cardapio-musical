import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.artisticName,
    super.nickname,
    super.searchName,
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
    super.unreadMessagesCount = 0,
    super.profileViewsCount = 0,
    super.isLive = false,
    super.liveUntil,
    super.scheduledShows,
    super.lastActiveAt,
    super.birthDate,
    super.verificationLevel = VerificationLevel.none,
    super.isParentalConsentGranted = false,
    super.isDobVisible = true,
    super.isPixVisible = true,
    super.profileType,
    super.subType,
    super.artistScore,
    super.professionalLevel,
    super.minSuggestedCache,
    super.maxSuggestedCache,
    super.showProfessionalBadge = true,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String id) {
    return UserProfileModel(
      id: id,
      email: json['email'] ?? '',
      artisticName: _getName(json),
      nickname: json['nickname'],
      searchName: json['searchName'],
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
      unreadMessagesCount: json['unreadMessagesCount'] ?? 0,
      profileViewsCount: json['profileViewsCount'] ?? 0,
      isLive: json['isLive'] ?? false,
      liveUntil: json['liveUntil'] != null
          ? (json['liveUntil'] as Timestamp).toDate()
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? (json['lastActiveAt'] as Timestamp).toDate()
          : null,
      scheduledShows: json['scheduledShows'] != null
          ? (json['scheduledShows'] as List).map((i) {
              return ShowInfo(
                date: (i['date'] as Timestamp).toDate(),
                location: i['location'] ?? '',
              );
            }).toList()
          : null,
      birthDate: json['birthDate'] != null
          ? (json['birthDate'] as Timestamp).toDate()
          : null,
      verificationLevel: VerificationLevel.values.firstWhere(
        (e) => e.name == (json['verificationLevel'] ?? 'none'),
        orElse: () => VerificationLevel.none,
      ),
      isParentalConsentGranted: json['isParentalConsentGranted'] ?? false,
      isDobVisible: json['isDobVisible'] ?? true,
      isPixVisible: json['isPixVisible'] ?? true,
      profileType: json['profileType'],
      subType: json['subType'],
      artistScore: json['artistScore'],
      professionalLevel: json['professionalLevel'],
      minSuggestedCache: (json['minSuggestedCache'] as num?)?.toDouble(),
      maxSuggestedCache: (json['maxSuggestedCache'] as num?)?.toDouble(),
      showProfessionalBadge: json['showProfessionalBadge'] ?? true,
    );
  }

  static String _getName(Map<String, dynamic> json) {
    final candidates = [
      'artisticName',
      'artistic_name',
      'name',
      'displayName',
      'display_name',
      'username',
      'full_name',
      'fullName',
      'email'
    ];
    for (final key in candidates) {
      final val = json[key];
      if (val != null && val is String && val.trim().isNotEmpty) {
        if (key == 'email' && val.contains('@')) {
          return val.split('@')[0];
        }
        return val;
      }
    }
    return 'Artista Sem Nome';
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'artisticName': artisticName,
      'nickname': nickname,
      'searchName': searchName,
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
      'unreadMessagesCount': unreadMessagesCount,
      'profileViewsCount': profileViewsCount,
      'isLive': isLive,
      'liveUntil': liveUntil != null ? Timestamp.fromDate(liveUntil!) : null,
      'scheduledShows': scheduledShows?.map((i) {
        return {
          'date': Timestamp.fromDate(i.date),
          'location': i.location,
        };
      }).toList(),
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'verificationLevel': verificationLevel.name,
      'isParentalConsentGranted': isParentalConsentGranted,
      'isDobVisible': isDobVisible,
      'isPixVisible': isPixVisible,
      'profileType': profileType,
      'subType': subType,
      'artistScore': artistScore,
      'professionalLevel': professionalLevel,
      'minSuggestedCache': minSuggestedCache,
      'maxSuggestedCache': maxSuggestedCache,
      'showProfessionalBadge': showProfessionalBadge,
    };
  }
}
