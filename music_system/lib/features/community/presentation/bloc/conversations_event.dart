import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class ConversationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConversationsStarted extends ConversationsEvent {
  final String userId;
  ConversationsStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ConversationsUpdated extends ConversationsEvent {
  final List<ConversationEntity> conversations;
  ConversationsUpdated(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class FollowingProfilesUpdated extends ConversationsEvent {
  final List<UserProfile> profiles;
  FollowingProfilesUpdated(this.profiles);

  @override
  List<Object?> get props => [profiles];
}

class ConversationsErrorOccurred extends ConversationsEvent {
  final String message;
  ConversationsErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
