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
    return StoryModel.fromJson({...data, 'id': doc.id});
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorPhotoUrl: json['authorPhotoUrl'],
      mediaUrl: json['mediaUrl'] ?? json['imageUrl'] ?? '',
      mediaType: json['mediaType'] ?? 'image',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] is Timestamp
              ? (json['expiresAt'] as Timestamp).toDate()
              : DateTime.parse(json['expiresAt']))
          : DateTime.now().add(const Duration(hours: 24)),
      viewers: List<String>.from(json['viewers'] ?? []),
      effects: json['effects'] != null
          ? StoryEffects.fromJson(json['effects'] as Map<String, dynamic>)
          : null,
      caption: json['caption'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewers': viewers,
      'effects': effects?.toJson(),
      'caption': caption,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['expiresAt'] = Timestamp.fromDate(expiresAt);
    return json;
  }
}
