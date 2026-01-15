import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/social_graph_repository.dart';

class UnfollowUser {
  final SocialGraphRepository repository;

  UnfollowUser(this.repository);

  Future<Either<Failure, void>> call(
    String currentUserId,
    String targetUserId,
  ) {
    return repository.unfollowUser(currentUserId, targetUserId);
  }
}
