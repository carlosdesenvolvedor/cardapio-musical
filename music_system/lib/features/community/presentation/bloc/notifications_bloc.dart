import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository repository;
  final ChatRepository chatRepository;
  StreamSubscription? _subscription;
  StreamSubscription? _chatSubscription;

  NotificationsBloc({required this.repository, required this.chatRepository})
      : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsUpdated>(_onUpdated);
    on<MarkNotificationAsRead>(_onMarkAsRead);

    on<NotificationsErrorOccurred>(_onErrorOccurred);
    on<UnreadChatCountUpdated>(_onUnreadChatCountUpdated);
  }

  void _onUnreadChatCountUpdated(
      UnreadChatCountUpdated event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(unreadMessageCount: event.count));
  }

  void _onErrorOccurred(
    NotificationsErrorOccurred event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    await repository.markAsRead(event.userId, event.notificationId);
  }

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));

    await _subscription?.cancel();
    _subscription = repository.streamNotifications(event.userId).listen(
      (notifications) {
        add(NotificationsUpdated(notifications));
      },
      onError: (e) {
        add(NotificationsErrorOccurred(e.toString()));
      },
    );

    await _chatSubscription?.cancel();
    _chatSubscription =
        chatRepository.streamUnreadCount(event.userId).listen((count) {
      add(UnreadChatCountUpdated(count));
    }, onError: (error) {
      // Don't stop notifications if unread count fails (likely index error)
      print('BACKEND ERROR: Unread Chat Count Failed: $error');
    });
  }

  void _onUpdated(
    NotificationsUpdated event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      state.copyWith(
        status: NotificationsStatus.success,
        notifications: event.notifications,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _chatSubscription?.cancel();
    return super.close();
  }
}
