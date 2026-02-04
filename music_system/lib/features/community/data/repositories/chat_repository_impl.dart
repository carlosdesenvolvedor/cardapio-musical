import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore firestore;
  final NotificationRepository notificationRepository;

  ChatRepositoryImpl({
    required this.firestore,
    required this.notificationRepository,
  });

  String _getChatId(String id1, String id2) {
    return id1.compareTo(id2) > 0 ? '${id1}_$id2' : '${id2}_$id1';
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String type = 'text',
    String? mediaUrl,
    String? senderName,
    String? senderPhoto,
  }) async {
    try {
      final chatId = _getChatId(senderId, receiverId);
      final batch = firestore.batch();

      // 1. Add Message to subcollection
      final messageRef = firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        mediaUrl: mediaUrl,
        createdAt: DateTime.now(),
      );

      batch.set(messageRef, message.toFirestore());

      // 2. Update/Create Chat Document (Last Message)
      final chatRef = firestore.collection('chats').doc(chatId);

      String lastMessage = text;
      if (type == 'image') lastMessage = '📷 Foto';
      if (type == 'audio') lastMessage = '🎤 Mensagem de voz';

      batch.set(
          chatRef,
          {
            'lastMessage': lastMessage,
            'lastMessageAt': FieldValue.serverTimestamp(),
            'participants': [senderId, receiverId],
          },
          SetOptions(merge: true));

      await batch.commit();

      // Create Notification
      if (senderName != null) {
        notificationRepository.createNotification(
          NotificationEntity(
            id: '',
            recipientId: receiverId,
            senderId: senderId,
            senderName: senderName,
            senderPhotoUrl: senderPhoto,
            type: NotificationType.message,
            message: text,
            createdAt: DateTime.now(),
          ),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<MessageEntity>> streamMessages({
    required String senderId,
    required String receiverId,
  }) {
    final chatId = _getChatId(senderId, receiverId);
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<ConversationEntity>> streamConversations(String userId) {
    return firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<Either<Failure, void>> markAsRead(String chatId, String userId) async {
    try {
      final query = firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return const Right(null);

      final batch = firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markChatAsRead(
      String userId, String otherUserId) async {
    final chatId = _getChatId(userId, otherUserId);
    return markAsRead(chatId, userId);
  }

  @override
  Stream<int> streamUnreadCount(String userId) {
    // This is a bit complex in Firestore structure.
    // Ideally, we'd have a 'unreadCounts' collection or field on the user profile.
    // Querying all messages across all chats is too expensive.
    // Optimization: Query 'chats' where user is participant, then listen to unread messages? Too many listeners.
    // Alternative: We can count unread messages by querying the 'chats' collection if we duplicated unread counts there.
    // But currently structure is chats/{chatId}/messages/{messageId} with isRead=false and receiverId=userId.
    // Query group is best here.
    return firestore
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      print(
          'BACKEND ERROR: streamUnreadCount failed. Usually requires a composite index on collectionGroup "messages" (receiverId and isRead).');
      print('Error details: $error');
      return 0; // Fallback to 0 unread messages
    });
  }
}
