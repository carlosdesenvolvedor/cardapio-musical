import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Stream<List<NotificationEntity>> streamNotifications(String userId);
  Future<Either<Failure, void>> markAsRead(
    String userId,
    String notificationId,
  );
  Future<Either<Failure, void>> createNotification(
    NotificationEntity notification,
  );
}
