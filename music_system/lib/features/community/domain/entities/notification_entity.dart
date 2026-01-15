import 'package:equatable/equatable.dart';

enum NotificationType { like, comment, follow, message, system }

class NotificationEntity extends Equatable {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final NotificationType type;
  final String? postId;
  final String? message;
  final DateTime createdAt;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.type,
    this.postId,
    this.message,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
    id,
    recipientId,
    senderId,
    senderName,
    senderPhotoUrl,
    type,
    postId,
    message,
    createdAt,
    isRead,
  ];
}
