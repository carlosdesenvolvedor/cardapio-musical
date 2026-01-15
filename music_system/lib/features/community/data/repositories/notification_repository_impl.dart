import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore firestore;

  NotificationRepositoryImpl({required this.firestore});

  @override
  Stream<List<NotificationEntity>> streamNotifications(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createNotification(
    NotificationEntity notification,
  ) async {
    try {
      final model = NotificationModel(
        id: '',
        recipientId: notification.recipientId,
        senderId: notification.senderId,
        senderName: notification.senderName,
        senderPhotoUrl: notification.senderPhotoUrl,
        type: notification.type,
        postId: notification.postId,
        message: notification.message,
        createdAt: notification.createdAt,
      );

      await firestore
          .collection('users')
          .doc(notification.recipientId)
          .collection('notifications')
          .add(model.toFirestore());

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
