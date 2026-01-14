import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String imageUrl;
  final String caption;
  final List<String> likes;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, authorId, authorName, authorPhotoUrl, imageUrl, caption, likes, createdAt];
}
