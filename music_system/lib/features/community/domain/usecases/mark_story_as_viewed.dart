import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/story_repository.dart';

class MarkStoryAsViewed {
  final StoryRepository repository;

  MarkStoryAsViewed(this.repository);

  Future<Either<Failure, void>> call(String storyId, String userId) async {
    return await repository.markStoryAsViewed(storyId, userId);
  }
}
