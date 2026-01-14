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
        fcmToken
      ];
}
