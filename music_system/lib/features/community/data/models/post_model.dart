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
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      imageUrl: data['imageUrl'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      postType: data['postType'] ?? 'image',
      caption: data['caption'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      taggedUserIds: List<String>.from(data['taggedUserIds'] ?? []),
      collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
      musicData: data['musicData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'imageUrl': imageUrl,
      'mediaUrls': mediaUrls,
      'postType': postType,
      'caption': caption,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
      'taggedUserIds': taggedUserIds,
      'collaboratorIds': collaboratorIds,
      'musicData': musicData,
    };
  }
}
