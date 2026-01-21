import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/story_model.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final FirebaseFirestore firestore;

  StoryRepositoryImpl({required this.firestore});

  @override
  Future<Either<Failure, List<StoryEntity>>> getActiveStories() async {
    try {
      final now = DateTime.now();
      // Buscamos todos os stories recentes (últimos 2 dias) para garantir que pegamos os ativos
      // e aplicamos o filtro de expiresAt em memória para evitar index issues complicados
      final snapshot = await firestore
          .collection('stories')
          .where('createdAt',
              isGreaterThan:
                  Timestamp.fromDate(now.subtract(const Duration(days: 2))))
          .get();

      final stories = snapshot.docs
          .map((doc) {
            try {
              return StoryModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Erro ao mapear story ${doc.id}: $e');
              return null;
            }
          })
          .whereType<StoryModel>()
          .where((story) {
            return story.expiresAt.isAfter(now);
          })
          .toList();

      debugPrint('Stories carregados: ${stories.length}');

      // Ordenar em memória: mais recentes primeiro
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(stories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createStory(StoryEntity story) async {
    try {
      final model = StoryModel(
        id: story.id,
        authorId: story.authorId,
        authorName: story.authorName,
        authorPhotoUrl: story.authorPhotoUrl,
        mediaUrl: story.mediaUrl,
        mediaType: story.mediaType,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        viewers: story.viewers,
      );

      await firestore.collection('stories').add(model.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markStoryAsViewed(
    String storyId,
    String userId,
  ) async {
    try {
      await firestore.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([userId]),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStory(String storyId) async {
    try {
      await firestore.collection('stories').doc(storyId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
