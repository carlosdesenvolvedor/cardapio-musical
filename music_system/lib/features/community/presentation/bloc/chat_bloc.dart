import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/stream_messages.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessage sendMessage;
  final StreamMessages streamMessages;
  StreamSubscription? _messagesSubscription;

  String? _currentSenderId;
  String? _currentReceiverId;

  ChatBloc({required this.sendMessage, required this.streamMessages})
      : super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<MessageSentRequested>(_onMessageSentRequested);
  }

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    _currentSenderId = event.senderId;
    _currentReceiverId = event.receiverId;

    emit(state.copyWith(status: ChatStatus.loading));

    await _messagesSubscription?.cancel();
    _messagesSubscription = streamMessages(
      senderId: event.senderId,
      receiverId: event.receiverId,
    ).listen((messages) {
      add(MessagesUpdated(messages));
    });
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(status: ChatStatus.success, messages: event.messages));
  }

  Future<void> _onMessageSentRequested(
    MessageSentRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentSenderId == null || _currentReceiverId == null) {
      print(
          'DEBUG: ChatBloc error - IDs are null (Sender: $_currentSenderId, Receiver: $_currentReceiverId)');
      return;
    }

    print('DEBUG: ChatBloc sending message - Type: ${event.type}');
    final result = await sendMessage(
      senderId: _currentSenderId!,
      receiverId: _currentReceiverId!,
      text: event.text,
      type: event.type,
      mediaUrl: event.mediaUrl,
      senderName: event.senderName,
      senderPhoto: event.senderPhoto,
    );

    result.fold(
      (failure) => print(
          'DEBUG: ChatBloc error - sendMessage failed: ${failure.toString()}'),
      (_) => print('DEBUG: ChatBloc success - message sent'),
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
