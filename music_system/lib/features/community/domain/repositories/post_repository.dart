import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/post_entity.dart';

class PostResponse {
  final List<PostEntity> posts;
  final DocumentSnapshot? lastDoc;
  PostResponse({required this.posts, this.lastDoc});
}

abstract class PostRepository {
  Future<Either<Failure, PostResponse>> getGlobalPosts({
    int limit = 10,
    DocumentSnapshot? lastDoc,
  });
  Future<Either<Failure, PostResponse>> getFollowingPosts({
    required List<String> followingIds,
    int limit = 10,
    DocumentSnapshot? lastDoc,
  });
  Future<Either<Failure, void>> createPost(PostEntity post);
  Future<Either<Failure, void>> toggleLike(String postId, String userId);
  Future<Either<Failure, void>> addComment({
    required String postId,
    required String postAuthorId,
    required Map<String, dynamic> comment,
  });
  Stream<QuerySnapshot> getComments(String postId);
  Future<Either<Failure, void>> addReply({
    required String postId,
    required String commentId,
    required String commentAuthorId,
    required Map<String, dynamic> reply,
  });
  Stream<QuerySnapshot> getReplies(String postId, String commentId);
  Future<Either<Failure, PostEntity>> getPost(String postId);
  Future<Either<Failure, PostResponse>> getPostsByUser({
    required String userId,
    int limit = 10,
    DocumentSnapshot? lastDoc,
  });
  Future<Either<Failure, void>> savePost(String userId, String postId);
  Future<Either<Failure, void>> unsavePost(String userId, String postId);
  Future<Either<Failure, bool>> isPostSaved(String userId, String postId);
}
