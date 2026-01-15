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
}
