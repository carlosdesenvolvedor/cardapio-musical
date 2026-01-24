import 'package:equatable/equatable.dart';
import 'story_effects.dart';

class StoryEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;
  final StoryEffects? effects;

  const StoryEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    required this.viewers,
    this.effects,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => mediaType == 'video';

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorPhotoUrl,
        mediaUrl,
        mediaType,
        createdAt,
        expiresAt,
        viewers,
        effects,
      ];
}
