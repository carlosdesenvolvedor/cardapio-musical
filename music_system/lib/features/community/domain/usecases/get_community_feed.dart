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
  }) async {
    // Se logado (followingIds != null)
    if (followingIds != null) {
      if (followingIds.isEmpty) {
        // Se segue ninguém, feed vazio (ou poderia ser recomendações, mas por hora vazio para ser restritivo)
        return Right(PostResponse(posts: [], lastDoc: null));
      }
      return repository.getFollowingPosts(
        followingIds: followingIds,
        limit: limit,
        lastDoc: lastDoc,
      );
    }

    // Se não logado (visitante), mostra o feed global
    return repository.getGlobalPosts(limit: limit, lastDoc: lastDoc);
  }
}
