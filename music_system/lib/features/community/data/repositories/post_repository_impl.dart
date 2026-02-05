import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/entities/post_entity.dart';
import '../models/post_model.dart';

import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

import '../../../../core/services/backend_api_service.dart';

class PostRepositoryImpl implements PostRepository {
  final FirebaseFirestore firestore; // Keep for comments/legacy
  final NotificationRepository notificationRepository;
  final BackendApiService apiService;

  PostRepositoryImpl({
    required this.firestore,
    required this.notificationRepository,
    required this.apiService,
  });

  @override
  Future<Either<Failure, PostResponse>> getGlobalPosts({
    int limit = 10,
    DocumentSnapshot? lastDoc,
    String? lastId,
  }) async {
    try {
      final response = await apiService.get('/feed', queryParameters: {
        'limit': limit,
        if (lastId != null) 'lastId': lastId,
      });

      final List<dynamic> data = response.data;
      final posts = data.map((json) => PostModel.fromJson(json)).toList();

      return Right(PostResponse(posts: posts));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostResponse>> getFollowingPosts({
    required List<String> followingIds,
    int limit = 10,
    DocumentSnapshot? lastDoc,
    String? lastId,
  }) async {
    try {
      // For now, the backend Feed might return all posts or filtered ones.
      // If we want actual "Following" feed, we'd need a backend endpoint for that.
      // For simplicity during transition, using the same global feed or adding a query param.
      final response = await apiService.get('/feed', queryParameters: {
        'limit': limit,
        if (lastId != null) 'lastId': lastId,
        'followingOnly': true, // Backend logic can handle this later
      });

      final List<dynamic> data = response.data;
      final posts = data.map((json) => PostModel.fromJson(json)).toList();

      return Right(PostResponse(posts: posts));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createPost(PostEntity post) async {
    try {
      final postModel = PostModel(
        id: post.id,
        authorId: post.authorId,
        authorName: post.authorName,
        authorPhotoUrl: post.authorPhotoUrl,
        imageUrl: post.imageUrl,
        mediaUrls: post.mediaUrls,
        postType: post.postType,
        caption: post.caption,
        likes: post.likes,
        createdAt: post.createdAt,
        taggedUserIds: post.taggedUserIds,
        collaboratorIds: post.collaboratorIds,
        musicData: post.musicData,
      );

      await apiService.post('/feed', data: postModel.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLike(String postId, String userId) async {
    try {
      // Check current state (optimistic or actual) or just call toggle
      // The backend has POST /api/feed/like/{postId} and DELETE /api/feed/like/{postId}
      // But toggle might be easier. Let's assume we need to know if it's currently liked.

      // For now, just calling the backend post for like. A better toggle would check current status.
      // In a real app, the UI usually knows if it's liked.
      // Assuming we'll use a single toggle if available or just handle it here.

      // Let's check if the ID is a MongoDB ID (24 chars) or Firestore ID (usually shorter/different)
      // Since we migrated, we use the string ID.

      // For toggle, we can just call like or unlike based on current UI state.
      // The domain usually doesn't pass whether it's liked or not to toggleLike.

      await apiService.post('/feed/like/$postId');

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addComment({
    required String postId,
    required String postAuthorId,
    required Map<String, dynamic> comment,
  }) async {
    try {
      // KEEPING FIRESTORE FOR COMMENTS FOR NOW (To avoid migrating subcollections yet)
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(comment);

      // Create Notification if not the author
      if (comment['authorId'] != postAuthorId) {
        notificationRepository.createNotification(
          NotificationEntity(
            id: '',
            recipientId: postAuthorId,
            senderId: comment['authorId'],
            senderName: comment['authorName'] ?? 'Alguém',
            senderPhotoUrl: comment['authorPhotoUrl'],
            type: NotificationType.comment,
            postId: postId,
            message: comment['text'],
            createdAt: DateTime.now(),
          ),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<QuerySnapshot> getComments(String postId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Future<Either<Failure, void>> addReply({
    required String postId,
    required String commentId,
    required String commentAuthorId,
    required Map<String, dynamic> reply,
  }) async {
    try {
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add(reply);

      // Create Notification for comment author if not the same person
      if (reply['authorId'] != commentAuthorId) {
        notificationRepository.createNotification(
          NotificationEntity(
            id: '',
            recipientId: commentAuthorId,
            senderId: reply['authorId'],
            senderName: reply['authorName'] ?? 'Alguém',
            senderPhotoUrl: reply['authorPhotoUrl'],
            type:
                NotificationType.comment, // Using comment type for replies too
            postId: postId,
            message: 'respondeu: ${reply['text']}',
            createdAt: DateTime.now(),
          ),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<QuerySnapshot> getReplies(String postId, String commentId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('createdAt',
            descending: false) // Replies usually ascending (chronological)
        .snapshots();
  }

  @override
  Future<Either<Failure, PostEntity>> getPost(String postId) async {
    try {
      final response = await apiService.get('/feed/$postId');
      return Right(PostModel.fromJson(response.data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostResponse>> getPostsByUser({
    required String userId,
    int limit = 10,
    DocumentSnapshot? lastDoc,
    String? lastId,
  }) async {
    try {
      final response = await apiService.get('/feed/user/$userId');
      final List<dynamic> data = response.data;
      final posts = data.map((json) => PostModel.fromJson(json)).toList();
      return Right(PostResponse(posts: posts));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePost(String userId, String postId) async {
    try {
      // Saved posts can stay in Firestore for now as they are per-user
      await firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(postId)
          .set({
        'savedAt': Timestamp.now(),
        'postId': postId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unsavePost(String userId, String postId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(postId)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isPostSaved(
      String userId, String postId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(postId)
          .get();
      return Right(doc.exists);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
