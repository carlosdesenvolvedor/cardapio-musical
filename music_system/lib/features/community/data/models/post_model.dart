import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    super.authorPhotoUrl,
    required super.imageUrl,
    super.mediaUrls,
    super.postType,
    required super.caption,
    required super.likes,
    required super.createdAt,
    super.taggedUserIds,
    super.collaboratorIds,
    super.musicData,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel.fromJson({...data, 'id': doc.id});
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorPhotoUrl: json['authorPhotoUrl'],
      imageUrl: json['imageUrl'] ?? '',
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      postType: json['postType'] ?? 'image',
      caption: json['caption'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      taggedUserIds: List<String>.from(json['taggedUserIds'] ?? []),
      collaboratorIds: List<String>.from(json['collaboratorIds'] ?? []),
      musicData: json['musicData'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'imageUrl': imageUrl,
      'mediaUrls': mediaUrls,
      'postType': postType,
      'caption': caption,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'taggedUserIds': taggedUserIds,
      'collaboratorIds': collaboratorIds,
      'musicData': musicData,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['createdAt'] = Timestamp.fromDate(createdAt);
    return json;
  }
}
