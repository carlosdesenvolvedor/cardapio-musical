import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message_entity.dart';
import '../entities/conversation_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, void>> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    String? senderPhoto,
  });

  Stream<List<MessageEntity>> streamMessages({
    required String senderId,
    required String receiverId,
  });

  Stream<List<ConversationEntity>> streamConversations(String userId);

  Future<Either<Failure, void>> markAsRead(String chatId, String userId);
}
