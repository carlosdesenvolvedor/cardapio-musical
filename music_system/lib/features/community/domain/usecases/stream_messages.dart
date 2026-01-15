import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class StreamMessages {
  final ChatRepository repository;

  StreamMessages(this.repository);

  Stream<List<MessageEntity>> call({
    required String senderId,
    required String receiverId,
  }) {
    return repository.streamMessages(
      senderId: senderId,
      receiverId: receiverId,
    );
  }
}
