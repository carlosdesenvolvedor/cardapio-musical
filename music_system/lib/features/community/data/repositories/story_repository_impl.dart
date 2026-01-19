import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/story_model.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final FirebaseFirestore firestore;

  StoryRepositoryImpl({required this.firestore});

  @override
  Future<Either<Failure, List<StoryEntity>>> getActiveStories() async {
    try {
      final now = DateTime.now();
      final snapshot = await firestore
          .collection('stories')
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      final stories = snapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();

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
      );

      await firestore.collection('stories').add(model.toFirestore());
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
      await firestore.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([userId]),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStory(String storyId) async {
    try {
      await firestore.collection('stories').doc(storyId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
