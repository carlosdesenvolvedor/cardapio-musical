import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class GetCommunityFeed {
  final PostRepository repository;

  GetCommunityFeed(this.repository);

  Future<Either<Failure, PostResponse>> call({
    List<String>? followingIds,
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) {
    if (followingIds != null && followingIds.isNotEmpty) {
      return repository.getFollowingPosts(
        followingIds: followingIds,
        limit: limit,
        lastDoc: lastDoc,
      );
    } else {
      return repository.getGlobalPosts(limit: limit, lastDoc: lastDoc);
    }
  }
}
