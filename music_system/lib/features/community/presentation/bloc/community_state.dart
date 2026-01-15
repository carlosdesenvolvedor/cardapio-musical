import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/story_entity.dart';

enum CommunityStatus { initial, loading, success, failure }

class CommunityState extends Equatable {
  final CommunityStatus status;
  final List<PostEntity> posts;
  final List<StoryEntity> stories;
  final bool hasReachedMax;
  final DocumentSnapshot? lastDoc;
  final String? errorMessage;

  const CommunityState({
    this.status = CommunityStatus.initial,
    this.posts = const <PostEntity>[],
    this.stories = const <StoryEntity>[],
    this.hasReachedMax = false,
    this.lastDoc,
    this.errorMessage,
  });

  CommunityState copyWith({
    CommunityStatus? status,
    List<PostEntity>? posts,
    List<StoryEntity>? stories,
    bool? hasReachedMax,
    DocumentSnapshot? lastDoc,
    String? errorMessage,
  }) {
    return CommunityState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      stories: stories ?? this.stories,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastDoc: lastDoc ?? this.lastDoc,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    posts,
    stories,
    hasReachedMax,
    lastDoc,
    errorMessage,
  ];
}
