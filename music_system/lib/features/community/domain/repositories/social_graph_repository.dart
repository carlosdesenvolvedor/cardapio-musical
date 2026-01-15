import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class SocialGraphRepository {
  Future<Either<Failure, void>> followUser(
    String currentUserId,
    String targetUserId, {
    String? senderName,
    String? senderPhoto,
  });
  Future<Either<Failure, void>> unfollowUser(
    String currentUserId,
    String targetUserId,
  );
  Future<Either<Failure, bool>> isFollowing(
    String currentUserId,
    String targetUserId,
  );
  Future<Either<Failure, List<String>>> getFollowingIds(String userId);
  Future<Either<Failure, List<String>>> getFollowersIds(String userId);
}
