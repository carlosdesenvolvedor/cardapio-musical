import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/usecases/get_community_feed.dart';
import '../../domain/usecases/get_active_stories.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final GetCommunityFeed getCommunityFeed;
  final GetActiveStories getActiveStories;
  final PostRepository postRepository;
  final NotificationRepository notificationRepository;

  CommunityBloc({
    required this.getCommunityFeed,
    required this.getActiveStories,
    required this.postRepository,
    required this.notificationRepository,
  }) : super(const CommunityState()) {
    on<FetchFeedStarted>(_onFetchFeedStarted);
    on<FetchStoriesStarted>(_onFetchStoriesStarted);
    on<LoadMorePostsRequested>(_onLoadMorePostsRequested);
    on<ToggleLikeRequested>(
      _onToggleLikeRequested,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 500))
          .switchMap(mapper),
    );
  }

  Future<void> _onFetchFeedStarted(
    FetchFeedStarted event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));

    // Carrega Feed
    final result = await getCommunityFeed(
      followingIds: event.followingIds,
      limit: 10,
    );

    // Carrega Stories simultaneamente ou logo após
    final storiesResult = await getActiveStories();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CommunityStatus.failure,
          errorMessage: failure.toString(),
        ),
      ),
      (response) {
        final posts = response.posts;
        final lastDoc = response.lastDoc;

        storiesResult.fold(
          (_) => emit(
            state.copyWith(
              status: CommunityStatus.success,
              posts: posts,
              lastDoc: lastDoc,
              hasReachedMax: posts.length < 10,
            ),
          ),
          (stories) {
            final filteredStories = event.followingIds != null
                ? stories
                    .where((s) => event.followingIds!.contains(s.authorId))
                    .toList()
                : stories;
            emit(
              state.copyWith(
                status: CommunityStatus.success,
                posts: posts,
                stories: filteredStories,
                lastDoc: lastDoc,
                hasReachedMax: posts.length < 10,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onFetchStoriesStarted(
    FetchStoriesStarted event,
    Emitter<CommunityState> emit,
  ) async {
    final result = await getActiveStories();
    result.fold(
      (failure) => null, // Silencioso para stories se falhar no meio
      (stories) {
        final filteredStories = event.followingIds != null
            ? stories
                .where((s) => event.followingIds!.contains(s.authorId))
                .toList()
            : stories;
        emit(state.copyWith(stories: filteredStories));
      },
    );
  }

  Future<void> _onLoadMorePostsRequested(
    LoadMorePostsRequested event,
    Emitter<CommunityState> emit,
  ) async {
    if (state.hasReachedMax) return;

    final result = await getCommunityFeed(
      followingIds: event.followingIds,
      lastDoc: state.lastDoc,
      limit: 10,
    );

    result.fold(
      (failure) => null, // Silencioso no scroll infinito
      (response) {
        if (response.posts.isEmpty) {
          emit(state.copyWith(hasReachedMax: true));
        } else {
          emit(
            state.copyWith(
              posts: List.of(state.posts)..addAll(response.posts),
              lastDoc: response.lastDoc,
              hasReachedMax: response.posts.length < 10,
            ),
          );
        }
      },
    );
  }

  Future<void> _onToggleLikeRequested(
    ToggleLikeRequested event,
    Emitter<CommunityState> emit,
  ) async {
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId) {
        final newLikes = List<String>.from(post.likes);
        if (newLikes.contains(event.userId)) {
          newLikes.remove(event.userId);
        } else {
          newLikes.add(event.userId);
        }
        return post.copyWith(likes: newLikes);
      }
      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));
    final result = await postRepository.toggleLike(event.postId, event.userId);

    // Check if it was a LIKE (userId was added)
    bool isLike = false;
    final post = state.posts.firstWhere((p) => p.id == event.postId);
    if (post.likes.contains(event.userId)) {
      isLike = true;
    }

    if (result.isRight() &&
        isLike && // Add this check
        event.senderName != null &&
        event.postAuthorId != null &&
        event.postAuthorId != event.userId) {
      notificationRepository.createNotification(
        NotificationEntity(
          id: '',
          recipientId: event.postAuthorId!,
          senderId: event.userId,
          senderName: event.senderName!,
          senderPhotoUrl: event.senderPhoto,
          type: NotificationType.like,
          postId: event.postId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}
