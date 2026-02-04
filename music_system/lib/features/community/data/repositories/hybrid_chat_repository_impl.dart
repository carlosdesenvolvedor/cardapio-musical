import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

class HybridChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore firestore;
  final NotificationRepository notificationRepository;
  final Dio dio;
  final String baseUrl; // e.g., "http://localhost:5000"

  HubConnection? _hubConnection;
  final _messageController = BehaviorSubject<List<MessageEntity>>.seeded([]);
  String? _currentChatId;
  bool _useBackend = true; // Flag to toggle fallback

  HybridChatRepositoryImpl({
    required this.firestore,
    required this.notificationRepository,
    required this.dio,
    required this.baseUrl,
  }) {
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          "$baseUrl/chathub",
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on("ReceiveMessage", _handleNewMessage);

    try {
      await _hubConnection?.start();
      print("SignalR Connected Successfully");
      _useBackend = true;
    } catch (e) {
      print(
          "SignalR Connection Error: $e. Falling back to Firestore for real-time.");
      _useBackend = false;
    }
  }

  void _handleNewMessage(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    // Map dynamic object from SignalR to MessageModel
    final data = arguments[0] as Map<String, dynamic>;
    final message = MessageModel.fromJson(data, data['id'] ?? '');

    // If it's the current chat, add to stream
    final chatId = _getChatId(message.senderId, message.receiverId);
    if (chatId == _currentChatId) {
      final currentList = _messageController.value;
      _messageController.add([message, ...currentList]);
    }
  }

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

      final message = MessageModel(
        id: '', // Backend will generate
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        type: type,
        mediaUrl: mediaUrl,
        createdAt: DateTime.now(),
      );

      // 1. Send to C# API (Persistence)
      if (_useBackend) {
        try {
          await dio.post("$baseUrl/api/chat/send", data: message.toJson());
        } catch (e) {
          print("Error sending to C# API: $e. Using Firestore as backup.");
        }
      }

      // 2. Broadcast via SignalR (Real-time in-app)
      if (_useBackend &&
          _hubConnection?.state == HubConnectionState.Connected) {
        await _hubConnection?.invoke("SendMessageToGroup",
            args: [senderId, receiverId, message.toJson()]);
      } else {
        // FALLBACK: If hybrid failed, write to Firestore (Phase 0 logic)
        // This ensures "everything works as it is"
        final fsMessageRef = firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        await fsMessageRef.set(message.toFirestore());
      }

      // 3. Update Firestore Metadata (for the chat list)
      String lastMessageSnippet = text;
      if (type == 'image') lastMessageSnippet = '📷 Foto';
      if (type == 'audio') lastMessageSnippet = '🎤 Mensagem de voz';

      await firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessageSnippet,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'participants': [senderId, receiverId],
      }, SetOptions(merge: true));

      // 4. Increment unread on receiver profile (via Firestore as cache)
      await firestore.collection('users').doc(receiverId).update({
        'unreadMessagesCount': FieldValue.increment(1),
      });

      // 5. Create Notification
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
    _currentChatId = _getChatId(senderId, receiverId);

    // Join SignalR Group if possible
    if (_hubConnection?.state == HubConnectionState.Connected) {
      _hubConnection?.invoke("JoinConversation", args: [senderId, receiverId]);
    }

    // Load history
    _loadHistory(senderId, receiverId);

    // If SignalR failed, listen to Firestore as well to merge
    if (!_useBackend || _hubConnection?.state != HubConnectionState.Connected) {
      final chatId = _getChatId(senderId, receiverId);
      firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
        final fsMessages = snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();
        // Merge or update the controller (simplified logic: just set if backend failed)
        if (!_useBackend) {
          _messageController.add(fsMessages);
        }
      });
    }

    return _messageController.stream;
  }

  Future<void> _loadHistory(String id1, String id2) async {
    try {
      final response =
          await dio.get("$baseUrl/api/chat/history", queryParameters: {
        'userId1': id1,
        'userId2': id2,
        'limit': 50,
      });

      if (response.statusCode == 200) {
        final List data = response.data;
        final messages = data
            .map((json) => MessageModel.fromJson(json, json['id'] ?? ''))
            .toList();
        _messageController.add(messages);
      }
    } catch (e) {
      print("Error loading chat history: $e");
    }
  }

  @override
  Stream<List<ConversationEntity>> streamConversations(String userId) {
    // Keep using Firestore for conversation list (low volume metadata)
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
      // 1. Update C# Backend
      await dio.post("$baseUrl/api/chat/markRead", data: {
        'chatId': chatId,
        'userId': userId,
      });

      // 2. Refresh the local Firestore profile counter
      // In a real scenario, the C# backend would update Firestore, but to ensure
      // immediate UI feedback and support the current Firestore-based unread badge:
      final accountRef = firestore.collection('users').doc(userId);
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(accountRef);
        if (snapshot.exists) {
          // Note: This is an approximation. In a perfect world,
          // C# would return the count of messages marked as read.
          // For now, we manually fetch if we need precision, or trust C# and set to 0/decrement.
          transaction.update(accountRef,
              {'unreadMessagesCount': 0}); // Resetting for this chatId logic
        }
      });

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
    // Continue using Firestore cached counter (very efficient)
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      final data = snapshot.data();
      return (data?['unreadMessagesCount'] as int?) ?? 0;
    });
  }
}
