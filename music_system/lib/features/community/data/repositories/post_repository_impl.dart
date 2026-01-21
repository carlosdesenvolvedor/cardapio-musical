import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/entities/post_entity.dart';
import '../models/post_model.dart';

import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

class PostRepositoryImpl implements PostRepository {
  final FirebaseFirestore firestore;
  final NotificationRepository notificationRepository;

  PostRepositoryImpl({
    required this.firestore,
    required this.notificationRepository,
  });

  @override
  Future<Either<Failure, PostResponse>> getGlobalPosts({
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final posts =
          snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

      final nextLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return Right(PostResponse(posts: posts, lastDoc: nextLastDoc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostResponse>> getFollowingPosts({
    required List<String> followingIds,
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      if (followingIds.isEmpty) {
        return Right(PostResponse(posts: const []));
      }

      final idsToQuery = followingIds.take(30).toList();

      Query query = firestore
          .collection('posts')
          .where('authorId', whereIn: idsToQuery)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final posts =
          snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

      // Sort in memory to avoid "Composite Index" requirement
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final nextLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return Right(PostResponse(posts: posts, lastDoc: nextLastDoc));
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
        caption: post.caption,
        likes: post.likes,
        createdAt: post.createdAt,
      );
      await firestore.collection('posts').add(postModel.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLike(String postId, String userId) async {
    try {
      final docRef = firestore.collection('posts').doc(postId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
        transaction.update(docRef, {'likes': likes});
      });

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
  Future<Either<Failure, PostEntity>> getPost(String postId) async {
    try {
      final doc = await firestore.collection('posts').doc(postId).get();
      if (!doc.exists) {
        return Left(ServerFailure('Publicação não encontrada'));
      }
      return Right(PostModel.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostResponse>> getPostsByUser({
    required String userId,
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          //.orderBy('createdAt', descending: true) // Removed to avoid index error
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final posts =
          snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

      // Sort in memory to fix missing index issue
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final nextLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return Right(PostResponse(posts: posts, lastDoc: nextLastDoc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
