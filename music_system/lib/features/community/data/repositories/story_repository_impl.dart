import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/story_model.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/story_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

class StoryRepositoryImpl implements StoryRepository {
  final FirebaseFirestore firestore;
  final NotificationRepository notificationRepository;

  StoryRepositoryImpl({
    required this.firestore,
    required this.notificationRepository,
  });

  @override
  Future<Either<Failure, List<StoryEntity>>> getActiveStories() async {
    try {
      final now = DateTime.now();
      // Buscamos todos os stories recentes (últimos 2 dias) para garantir que pegamos os ativos
      // e aplicamos o filtro de expiresAt em memória para evitar index issues complicados
      final snapshot = await firestore
          .collection('stories')
          .where('createdAt',
              isGreaterThan: Timestamp.fromDate(now.subtract(const Duration(
                  days: 7)))) // Aumentando para 7 dias para teste
          .get();

      debugPrint('Snapshot size: ${snapshot.docs.length}');

      final stories = snapshot.docs
          .map((doc) {
            try {
              final model = StoryModel.fromFirestore(doc);
              debugPrint(
                  'Story found: ID=${model.id}, ExpiresAt=${model.expiresAt}, Now=$now');
              return model;
            } catch (e) {
              debugPrint('Erro ao mapear story ${doc.id}: $e');
              return null;
            }
          })
          .whereType<StoryModel>()
          .where((story) {
            final isNotExpired = story.expiresAt.isAfter(now);
            if (!isNotExpired) {
              debugPrint('Filtering out EXPIRED story: ID=${story.id}');
            }
            return isNotExpired;
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

  @override
  Future<Either<Failure, void>> addStoryComment({
    required String storyId,
    required String storyAuthorId,
    required Map<String, dynamic> comment,
  }) async {
    try {
      await firestore
          .collection('stories')
          .doc(storyId)
          .collection('comments')
          .add(comment);

      // Create Notification if not the author
      if (comment['authorId'] != storyAuthorId) {
        notificationRepository.createNotification(
          NotificationEntity(
            id: '',
            recipientId: storyAuthorId,
            senderId: comment['authorId'],
            senderName: comment['authorName'] ?? 'Alguém',
            senderPhotoUrl: comment['authorPhotoUrl'],
            type: NotificationType.comment,
            storyId: storyId,
            message: 'comentou no seu story: ${comment['text']}',
            createdAt: DateTime.now(),
          ),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<QuerySnapshot> getStoryComments(String storyId) {
    return firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
