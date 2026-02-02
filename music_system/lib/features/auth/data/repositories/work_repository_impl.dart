import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:music_system/core/error/failures.dart';
import 'package:music_system/features/auth/data/models/work_model.dart';
import 'package:music_system/features/auth/domain/entities/work.dart';
import 'package:music_system/features/auth/domain/repositories/work_repository.dart';

import 'package:music_system/core/services/backend_storage_service.dart';

class WorkRepositoryImpl implements WorkRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final BackendStorageService backendStorage;

  WorkRepositoryImpl({
    required this.firestore,
    required this.storage,
    required this.backendStorage,
  });

  @override
  Future<Either<Failure, List<Work>>> getWorks(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('works')
          .orderBy('createdAt', descending: true)
          .get();

      final works =
          snapshot.docs.map((doc) => WorkModel.fromSnapshot(doc)).toList();
      return Right(works);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addWork(Work work, File? file) async {
    try {
      String? fileUrl;

      if (file != null) {
        // MIGRATION: Using Self-Hosted Backend for media
        // Old Firebase logic commented out
        /*
        final ref = storage.ref().child(
            'works/${work.userId}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
        */

        final path = await backendStorage.uploadFile(file, 'works');
        // The backend returns a relative path (bucket/key). We need to construct the full URL for the app to access.
        // Or if using Presigned/Stream, we might store the path and let the UI handle the base URL.
        // For now, let's store the full streaming URL.
        // Assuming BackendStorageService.baseUrl is reachable.
        // Actually, we should store the Path and let the UI resolve the streaming URL.
        // BUT to keep compatibility with existing Code that expects a full URL (http...), let's construct it.
        final String baseMediaUrl = (kDebugMode && !kIsWeb)
            ? "http://localhost/media/"
            : "https://136.248.64.90.nip.io/media/";
        fileUrl = "$baseMediaUrl$path";
      }

      final workModel = WorkModel(
        id: work.id,
        userId: work.userId,
        title: work.title,
        description: work.description,
        fileUrl: fileUrl ?? work.fileUrl,
        fileType: work.fileType,
        links: work.links,
        createdAt: work.createdAt,
      );

      await firestore
          .collection('users')
          .doc(work.userId)
          .collection('works')
          .add(workModel.toDocument());

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWork(Work work) async {
    try {
      final workModel = WorkModel(
        id: work.id,
        userId: work.userId,
        title: work.title,
        description: work.description,
        fileUrl: work.fileUrl,
        fileType: work.fileType,
        links: work.links,
        createdAt: work.createdAt,
      );

      await firestore
          .collection('users')
          .doc(work.userId)
          .collection('works')
          .doc(work.id)
          .update(workModel.toDocument());

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWork(String workId, String userId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('works')
          .doc(workId)
          .get();

      if (doc.exists) {
        final work = WorkModel.fromSnapshot(doc);
        if (work.fileUrl != null) {
          try {
            await storage.refFromURL(work.fileUrl!).delete();
          } catch (_) {}
        }
      }

      await firestore
          .collection('users')
          .doc(userId)
          .collection('works')
          .doc(workId)
          .delete();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
