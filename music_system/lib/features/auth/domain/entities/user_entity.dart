import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? nickname;
  final List<String> followingIds;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.nickname,
    this.followingIds = const [],
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? nickname,
    List<String>? followingIds,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      nickname: nickname ?? this.nickname,
      followingIds: followingIds ?? this.followingIds,
    );
  }

  @override
  List<Object?> get props =>
      [id, email, displayName, photoUrl, nickname, followingIds];
}
