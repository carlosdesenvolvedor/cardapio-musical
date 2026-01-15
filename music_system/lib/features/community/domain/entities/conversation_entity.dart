import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String? otherUserName;
  final String? otherUserPhotoUrl;

  const ConversationEntity({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    this.otherUserName,
    this.otherUserPhotoUrl,
  });

  @override
  List<Object?> get props => [
    id,
    participants,
    lastMessage,
    lastMessageAt,
    otherUserName,
    otherUserPhotoUrl,
  ];
}
