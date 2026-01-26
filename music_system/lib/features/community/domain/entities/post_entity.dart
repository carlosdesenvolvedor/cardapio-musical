import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String imageUrl; // Thumbnail ou primeiro item (retrocompatibilidade)
  final List<String> mediaUrls;
  final String postType; // 'image', 'video', 'carousel'
  final String caption;
  final List<String> likes;
  final DateTime createdAt;
  final List<String> taggedUserIds;
  final List<String> collaboratorIds;
  final Map<String, dynamic>? musicData;

  const PostEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.imageUrl,
    this.mediaUrls = const [],
    this.postType = 'image',
    required this.caption,
    required this.likes,
    required this.createdAt,
    this.taggedUserIds = const [],
    this.collaboratorIds = const [],
    this.musicData,
  });

  PostEntity copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? imageUrl,
    List<String>? mediaUrls,
    String? postType,
    String? caption,
    List<String>? likes,
    DateTime? createdAt,
    List<String>? taggedUserIds,
    List<String>? collaboratorIds,
    Map<String, dynamic>? musicData,
  }) {
    return PostEntity(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      postType: postType ?? this.postType,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      musicData: musicData ?? this.musicData,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorPhotoUrl,
        imageUrl,
        mediaUrls,
        postType,
        caption,
        likes,
        createdAt,
        taggedUserIds,
        collaboratorIds,
        musicData,
      ];
}
