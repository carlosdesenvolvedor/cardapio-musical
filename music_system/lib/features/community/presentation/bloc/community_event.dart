import 'package:equatable/equatable.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class FetchStoriesStarted extends CommunityEvent {
  final List<String>? followingIds;
  const FetchStoriesStarted({this.followingIds});

  @override
  List<Object?> get props => [followingIds];
}

class FetchFeedStarted extends CommunityEvent {
  final List<String>? followingIds;
  final bool isRefresh;

  const FetchFeedStarted({this.followingIds, this.isRefresh = false});

  @override
  List<Object?> get props => [followingIds, isRefresh];
}

class LoadMorePostsRequested extends CommunityEvent {
  final List<String>? followingIds;

  const LoadMorePostsRequested({this.followingIds});

  @override
  List<Object?> get props => [followingIds];
}

class ToggleLikeRequested extends CommunityEvent {
  final String postId;
  final String userId;
  final String? senderName;
  final String? senderPhoto;
  final String? postAuthorId;

  const ToggleLikeRequested({
    required this.postId,
    required this.userId,
    this.senderName,
    this.senderPhoto,
    this.postAuthorId,
  });

  @override
  List<Object?> get props => [
        postId,
        userId,
        senderName,
        senderPhoto,
        postAuthorId,
      ];
}
