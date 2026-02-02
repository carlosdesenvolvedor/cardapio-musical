import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationEntity> notifications;
  final String? errorMessage;
  final int unreadMessageCount;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const <NotificationEntity>[],
    this.errorMessage,
    this.unreadMessageCount = 0,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationEntity>? notifications,
    String? errorMessage,
    int? unreadMessageCount,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
    );
  }

  @override
  List<Object?> get props =>
      [status, notifications, errorMessage, unreadMessageCount];
}
