import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../../auth/domain/entities/user_profile.dart';

enum ConversationsStatus { initial, loading, success, failure }

class ConversationsState extends Equatable {
  final ConversationsStatus status;
  final List<ConversationEntity> conversations;
  final List<UserProfile> followingProfiles;
  final String? errorMessage;

  const ConversationsState({
    this.status = ConversationsStatus.initial,
    List<ConversationEntity>? conversations,
    List<UserProfile>? followingProfiles,
    this.errorMessage,
  }) : conversations = conversations ?? const [],
       followingProfiles = followingProfiles ?? const [];

  ConversationsState copyWith({
    ConversationsStatus? status,
    List<ConversationEntity>? conversations,
    List<UserProfile>? followingProfiles,
    String? errorMessage,
  }) {
    return ConversationsState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      followingProfiles: followingProfiles ?? this.followingProfiles,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversations,
    followingProfiles,
    errorMessage,
  ];
}
