import 'package:equatable/equatable.dart';

enum VerificationLevel { none, basic, kycFull }

class ShowInfo extends Equatable {
  final DateTime date;
  final String location;

  const ShowInfo({
    required this.date,
    required this.location,
  });

  @override
  List<Object?> get props => [date, location];
}

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String artisticName;
  final String? nickname;
  final String? searchName;
  final String pixKey;
  final String? photoUrl;
  final String? bio;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? facebookUrl;
  final List<String>? galleryUrls;
  final String? fcmToken;
  final int followersCount;
  final int followingCount;
  final int profileViewsCount;
  final bool isLive;
  final DateTime? liveUntil;
  final List<ShowInfo>? scheduledShows;
  final DateTime? lastActiveAt;
  final DateTime? birthDate;
  final VerificationLevel verificationLevel;
  final bool isParentalConsentGranted;
  final bool isDobVisible;
  final bool isPixVisible;

  const UserProfile({
    required this.id,
    required this.email,
    required this.artisticName,
    this.nickname,
    this.searchName,
    required this.pixKey,
    this.photoUrl,
    this.bio,
    this.instagramUrl,
    this.youtubeUrl,
    this.facebookUrl,
    this.galleryUrls,
    this.fcmToken,
    this.followersCount = 0,
    this.followingCount = 0,
    this.profileViewsCount = 0,
    this.isLive = false,
    this.liveUntil,
    this.scheduledShows,
    this.lastActiveAt,
    this.birthDate,
    this.verificationLevel = VerificationLevel.none,
    this.isParentalConsentGranted = false,
    this.isDobVisible = true,
    this.isPixVisible = true,
  });

  @override
  List<Object?> get props => [
        isDobVisible,
        isPixVisible,
      ];

  UserProfile copyWith({
    String? id,
    String? email,
    String? artisticName,
    String? nickname,
    String? searchName,
    String? pixKey,
    String? photoUrl,
    String? bio,
    String? instagramUrl,
    String? youtubeUrl,
    String? facebookUrl,
    List<String>? galleryUrls,
    String? fcmToken,
    int? followersCount,
    int? followingCount,
    int? profileViewsCount,
    bool? isLive,
    DateTime? liveUntil,
    List<ShowInfo>? scheduledShows,
    DateTime? lastActiveAt,
    DateTime? birthDate,
    VerificationLevel? verificationLevel,
    bool? isParentalConsentGranted,
    bool? isDobVisible,
    bool? isPixVisible,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      artisticName: artisticName ?? this.artisticName,
      nickname: nickname ?? this.nickname,
      searchName: searchName ?? this.searchName,
      pixKey: pixKey ?? this.pixKey,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      fcmToken: fcmToken ?? this.fcmToken,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      profileViewsCount: profileViewsCount ?? this.profileViewsCount,
      isLive: isLive ?? this.isLive,
      liveUntil: liveUntil ?? this.liveUntil,
      scheduledShows: scheduledShows ?? this.scheduledShows,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      birthDate: birthDate ?? this.birthDate,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      isParentalConsentGranted:
          isParentalConsentGranted ?? this.isParentalConsentGranted,
      isDobVisible: isDobVisible ?? this.isDobVisible,
      isPixVisible: isPixVisible ?? this.isPixVisible,
    );
  }
}
