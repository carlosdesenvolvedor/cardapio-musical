import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsStarted extends NotificationsEvent {
  final String userId;
  NotificationsStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NotificationsUpdated extends NotificationsEvent {
  final List<NotificationEntity> notifications;
  NotificationsUpdated(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class UnreadChatCountUpdated extends NotificationsEvent {
  final int count;
  UnreadChatCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

class MarkNotificationAsRead extends NotificationsEvent {
  final String userId;
  final String notificationId;
  MarkNotificationAsRead(this.userId, this.notificationId);

  @override
  List<Object?> get props => [userId, notificationId];
}

class NotificationsErrorOccurred extends NotificationsEvent {
  final String message;
  NotificationsErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
