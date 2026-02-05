import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/story_model.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/story_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

import '../../../../core/services/backend_api_service.dart';

class StoryRepositoryImpl implements StoryRepository {
  final FirebaseFirestore firestore; // Keep for comments/legacy
  final NotificationRepository notificationRepository;
  final BackendApiService apiService;

  StoryRepositoryImpl({
    required this.firestore,
    required this.notificationRepository,
    required this.apiService,
  });

  @override
  Future<Either<Failure, List<StoryEntity>>> getActiveStories() async {
    try {
      final response = await apiService.get('/feed/stories');
      final List<dynamic> data = response.data;
      final stories = data.map((json) => StoryModel.fromJson(json)).toList();

      return Right(stories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createStory(StoryEntity story) async {
    try {
      final model = StoryModel(
        id: story.id,
        authorId: story.authorId,
        authorName: story.authorName,
        authorPhotoUrl: story.authorPhotoUrl,
        mediaUrl: story.mediaUrl,
        mediaType: story.mediaType,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        viewers: story.viewers,
        effects: story.effects,
        caption: story.caption,
      );

      await apiService.post('/feed/stories', data: model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markStoryAsViewed(
    String storyId,
    String userId,
  ) async {
    try {
      // For now, we don't have a specific endpoint for viewing stories in the backend
      // But we could add POST /api/feed/stories/view/{id}
      // For now, skipping or keeping Firestore if it's too critical.
      // Since it's a "set" operation, let's skip for now or add to backend later.
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStory(String storyId) async {
    try {
      await apiService.delete('/feed/stories/$storyId');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addStoryComment({
    required String storyId,
    required String storyAuthorId,
    required Map<String, dynamic> comment,
  }) async {
    try {
      await firestore
          .collection('stories')
          .doc(storyId)
          .collection('comments')
          .add(comment);

      // Create Notification if not the author
      if (comment['authorId'] != storyAuthorId) {
        notificationRepository.createNotification(
          NotificationEntity(
            id: '',
            recipientId: storyAuthorId,
            senderId: comment['authorId'],
            senderName: comment['authorName'] ?? 'Alguém',
            senderPhotoUrl: comment['authorPhotoUrl'],
            type: NotificationType.comment,
            storyId: storyId,
            message: 'comentou no seu story: ${comment['text']}',
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
  Stream<QuerySnapshot> getStoryComments(String storyId) {
    return firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
