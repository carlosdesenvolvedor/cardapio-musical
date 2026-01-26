import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/story_entity.dart';

abstract class StoryRepository {
  Future<Either<Failure, List<StoryEntity>>> getActiveStories();
  Future<Either<Failure, void>> createStory(StoryEntity story);
  Future<Either<Failure, void>> markStoryAsViewed(
    String storyId,
    String userId,
  );
  Future<Either<Failure, void>> deleteStory(String storyId);
  Future<Either<Failure, void>> addStoryComment({
    required String storyId,
    required String storyAuthorId,
    required Map<String, dynamic> comment,
  });
  Stream<QuerySnapshot> getStoryComments(String storyId);
}
