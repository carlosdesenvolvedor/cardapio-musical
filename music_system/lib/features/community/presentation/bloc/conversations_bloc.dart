import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/stream_conversations.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/social_graph_repository.dart';
import '../../domain/entities/conversation_entity.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final StreamConversations streamConversations;
  final AuthRepository authRepository;
  final SocialGraphRepository socialGraphRepository;
  StreamSubscription? _conversationsSubscription;

  ConversationsBloc({
    required this.streamConversations,
    required this.authRepository,
    required this.socialGraphRepository,
  }) : super(const ConversationsState()) {
    on<ConversationsStarted>(_onConversationsStarted);
    on<ConversationsUpdated>(_onConversationsUpdated);
    on<FollowingProfilesUpdated>(_onFollowingProfilesUpdated);
    on<ConversationsErrorOccurred>(_onErrorOccurred);
  }

  void _onErrorOccurred(
    ConversationsErrorOccurred event,
    Emitter<ConversationsState> emit,
  ) {
    emit(
      state.copyWith(
        status: ConversationsStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onConversationsStarted(
    ConversationsStarted event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(state.copyWith(status: ConversationsStatus.loading));

    // Fetch following profiles as suggestions
    _loadFollowingProfiles(event.userId);

    await _conversationsSubscription?.cancel();
    _conversationsSubscription = streamConversations(event.userId).listen(
      (conversations) async {
        // Enrich with other user info
        final enriched = await Future.wait(
          conversations.map((conv) async {
            final otherId = conv.participants.firstWhere(
              (id) => id != event.userId,
            );
            final profileResult = await authRepository.getProfile(otherId);

            return profileResult.fold(
              (_) => conv,
              (profile) => ConversationEntity(
                id: conv.id,
                participants: conv.participants,
                lastMessage: conv.lastMessage,
                lastMessageAt: conv.lastMessageAt,
                otherUserName: profile.artisticName,
                otherUserPhotoUrl: profile.photoUrl,
              ),
            );
          }),
        );

        add(ConversationsUpdated(enriched));
      },
      onError: (e) {
        add(ConversationsErrorOccurred(e.toString()));
      },
    );
  }

  Future<void> _loadFollowingProfiles(String userId) async {
    final followingResult = await socialGraphRepository.getFollowingIds(userId);
    followingResult.fold((_) => null, (ids) async {
      if (ids.isNotEmpty) {
        final profilesResult = await authRepository.getProfiles(ids);
        profilesResult.fold(
          (_) => null,
          (profiles) => add(FollowingProfilesUpdated(profiles)),
        );
      }
    });
  }

  void _onConversationsUpdated(
    ConversationsUpdated event,
    Emitter<ConversationsState> emit,
  ) {
    emit(
      state.copyWith(
        status: ConversationsStatus.success,
        conversations: event.conversations,
      ),
    );
  }

  void _onFollowingProfilesUpdated(
    FollowingProfilesUpdated event,
    Emitter<ConversationsState> emit,
  ) {
    emit(state.copyWith(followingProfiles: event.profiles));
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    return super.close();
  }
}
