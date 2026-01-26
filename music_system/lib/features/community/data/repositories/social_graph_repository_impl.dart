import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/social_graph_repository.dart';

import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

class SocialGraphRepositoryImpl implements SocialGraphRepository {
  final FirebaseFirestore firestore;
  final NotificationRepository notificationRepository;

  SocialGraphRepositoryImpl({
    required this.firestore,
    required this.notificationRepository,
  });

  @override
  Future<Either<Failure, void>> followUser(
    String currentUserId,
    String targetUserId, {
    String? senderName,
    String? senderPhoto,
  }) async {
    try {
      final batch = firestore.batch();

      final followingRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      final followersRef = firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      batch.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});
      batch.set(followersRef, {'timestamp': FieldValue.serverTimestamp()});

      final currentUserRef = firestore.collection('users').doc(currentUserId);
      final targetUserRef = firestore.collection('users').doc(targetUserId);

      batch.set(currentUserRef, {'followingCount': FieldValue.increment(1)},
          SetOptions(merge: true));
      batch.set(targetUserRef, {'followersCount': FieldValue.increment(1)},
          SetOptions(merge: true));

      await batch.commit();

      // Create Notification
      if (senderName != null) {
        notificationRepository.createNotification(
          NotificationEntity(
            id: '',
            recipientId: targetUserId,
            senderId: currentUserId,
            senderName: senderName,
            senderPhotoUrl: senderPhoto,
            type: NotificationType.follow,
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
  Future<Either<Failure, void>> unfollowUser(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final batch = firestore.batch();

      final followingRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      final followersRef = firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      batch.delete(followingRef);
      batch.delete(followersRef);

      final currentUserRef = firestore.collection('users').doc(currentUserId);
      final targetUserRef = firestore.collection('users').doc(targetUserId);

      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
      });

      batch.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFollowing(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();
      return Right(doc.exists);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFollowingIds(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();
      final ids = snapshot.docs.map((doc) => doc.id).toList();
      return Right(ids);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFollowersIds(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();
      final ids = snapshot.docs.map((doc) => doc.id).toList();
      return Right(ids);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
