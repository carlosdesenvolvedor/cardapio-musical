import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/story_entity.dart';
import '../repositories/story_repository.dart';

class GetActiveStories {
  final StoryRepository repository;

  GetActiveStories(this.repository);

  Future<Either<Failure, List<StoryEntity>>> call() async {
    return await repository.getActiveStories();
  }
}
