import '../entities/conversation_entity.dart';
import '../repositories/chat_repository.dart';

class StreamConversations {
  final ChatRepository repository;

  StreamConversations(this.repository);

  Stream<List<ConversationEntity>> call(String userId) {
    return repository.streamConversations(userId);
  }
}
