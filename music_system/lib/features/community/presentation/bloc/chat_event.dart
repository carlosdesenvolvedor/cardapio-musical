import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  final String senderId;
  final String receiverId;

  ChatStarted({required this.senderId, required this.receiverId});

  @override
  List<Object?> get props => [senderId, receiverId];
}

class MessagesUpdated extends ChatEvent {
  final List<MessageEntity> messages;

  MessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

class MessageSentRequested extends ChatEvent {
  final String text;
  final String? senderName;
  final String? senderPhoto;

  MessageSentRequested(this.text, {this.senderName, this.senderPhoto});

  @override
  List<Object?> get props => [text, senderName, senderPhoto];
}
