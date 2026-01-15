import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String artisticName;
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
  final bool isLive;
  final DateTime? lastActiveAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.artisticName,
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
    this.isLive = false,
    this.lastActiveAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    artisticName,
    pixKey,
    photoUrl,
    bio,
    instagramUrl,
    youtubeUrl,
    facebookUrl,
    galleryUrls,
    fcmToken,
    followersCount,
    followingCount,
    isLive,
    lastActiveAt,
  ];
}
