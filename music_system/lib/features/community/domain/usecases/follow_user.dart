import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/social_graph_repository.dart';

class FollowUser {
  final SocialGraphRepository repository;

  FollowUser(this.repository);

  Future<Either<Failure, void>> call(
    String currentUserId,
    String targetUserId, {
    String? senderName,
    String? senderPhoto,
  }) {
    return repository.followUser(
      currentUserId,
      targetUserId,
      senderName: senderName,
      senderPhoto: senderPhoto,
    );
  }
}
