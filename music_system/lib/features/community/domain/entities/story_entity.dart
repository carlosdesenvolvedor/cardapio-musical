import 'package:equatable/equatable.dart';

class StoryEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;

  const StoryEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    required this.viewers,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
    id,
    authorId,
    authorName,
    authorPhotoUrl,
    imageUrl,
    createdAt,
    expiresAt,
    viewers,
  ];
}
