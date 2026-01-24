import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<Either<Failure, void>> call({
    required String senderId,
    required String receiverId,
    required String text,
    String type = 'text',
    String? mediaUrl,
    String? senderName,
    String? senderPhoto,
  }) {
    return repository.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      senderName: senderName,
      senderPhoto: senderPhoto,
    );
  }
}
