import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/story_effects.dart';

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
    super.effects,
    super.caption,
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
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: (data['expiresAt'] is Timestamp)
          ? (data['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 24)),
      viewers: List<String>.from(data['viewers'] ?? []),
      effects: data['effects'] != null
          ? StoryEffects.fromJson(data['effects'] as Map<String, dynamic>)
          : null,
      caption: data['caption'],
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
      'effects': effects?.toJson(),
      'caption': caption,
    };
  }
}
