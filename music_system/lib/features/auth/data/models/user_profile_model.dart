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
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String id) {
    return UserProfileModel(
      id: id,
      email: json['email'] ?? '',
      artisticName: json['artisticName'] ?? '',
      pixKey: json['pixKey'] ?? '',
      photoUrl: json['photoUrl'],
      bio: json['bio'],
      instagramUrl: json['instagramUrl'],
      youtubeUrl: json['youtubeUrl'],
      facebookUrl: json['facebookUrl'],
      galleryUrls: json['galleryUrls'] != null ? List<String>.from(json['galleryUrls']) : null,
      fcmToken: json['fcmToken'],
    );
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
    };
  }
}
