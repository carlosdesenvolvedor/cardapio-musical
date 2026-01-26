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

      // Firestore whereIn supports up to 30 unique IDs.
      final uniqueIds = followingIds.toSet().toList();
      List<String> idsToQuery;
      if (uniqueIds.length > 30) {
        // Garante que o usuário logado (último da lista) está incluído
        final lastId = uniqueIds.last;
        idsToQuery = uniqueIds.sublist(0, 29);
        if (!idsToQuery.contains(lastId)) {
          idsToQuery.add(lastId);
        }
      } else {
        idsToQuery = uniqueIds;
      }

      Query query = firestore
          .collection('posts')
          .where('authorId', whereIn: idsToQuery)
          .orderBy('createdAt', descending: true) // Critical: Server-side sort
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final posts =
          snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

      // Memory sort is no longer strictly needed but kept as fallback/protection
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final nextLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return Right(PostResponse(posts: posts, lastDoc: nextLastDoc));
    } catch (e) {
      print('!!! ERRO CRÍTICO NO FEED: $e');
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
          .orderBy('createdAt',
              descending: true) // Re-added with server-side sort requirement
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
      print('!!! ERRO CRÍTICO NO PERFIL: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePost(String userId, String postId) async {
    try {
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
