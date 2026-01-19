import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/story_entity.dart';

class StoryModel extends StoryEntity {
  const StoryModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    super.authorPhotoUrl,
    required super.mediaUrl,
    required super.mediaType,
    required super.createdAt,
    required super.expiresAt,
    required super.viewers,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      mediaUrl: data['mediaUrl'] ?? data['imageUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      viewers: List<String>.from(data['viewers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewers': viewers,
    };
  }
}
