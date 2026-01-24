import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String type; // 'text', 'image', 'audio'
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = 'text',
    this.mediaUrl,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        text,
        type,
        mediaUrl,
        createdAt,
        isRead,
      ];
}
