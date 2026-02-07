import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../../core/error/failures.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';
import 'auth_repository_impl.dart';

class AuthRepositoryApiImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;
  final BackendApiService apiService;
  // We keep the original impl reference or logic for auth-specific tasks if needed,
  // or duplicate the simple auth logic here.
  final AuthRepositoryImpl? legacyRepository; // Optional fallbacks if needed

  AuthRepositoryApiImpl({
    required this.firebaseAuth,
    required this.apiService,
    this.legacyRepository,
  });

  @override
  Future<Either<Failure, UserEntity>> signIn(
      String email, String password) async {
    // Auth is still Firebase
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(_mapFirebaseUser(credential.user!));
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erro ao fazer login'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    // Delegate to legacy or re-implement Google Sign In logic logic here
    // For simplicity in this shadow file, I'll assume we duplicate the logic or delegate
    if (legacyRepository != null) {
      return legacyRepository!.signInWithGoogle();
    }
    return Left(
        ServerFailure("Google Sign In not implemented in API repo yet"));
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(
      String email, String password, String name) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);

      // CREATE PROFILE ON API instead of Firestore
      final profile = UserProfileModel(
        id: user.uid,
        email: user.email ?? '',
        artisticName: name,
        pixKey: '',
      );

      try {
        await apiService.post('/profile', data: profile.toApiJson());
      } catch (e) {
        // If API fails, we might have a consistency issue.
        // In this phase, we might want to dual-write or just fail.
        return Left(ServerFailure("Account created but profile failed: $e"));
      }

      return Right(_mapFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erro ao criar conta'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await firebaseAuth.signOut();
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    return Right(user != null ? _mapFirebaseUser(user) : null);
  }

  @override
  Stream<UserEntity?> get authStateChanges => firebaseAuth
      .authStateChanges()
      .map((user) => user != null ? _mapFirebaseUser(user) : null);

  // --- API BASED PROFILE METHODS ---

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      final endpoint =
          (userId == currentUserId) ? '/profile/me' : '/profile/$userId';

      final response = await apiService.get(endpoint);
      return Right(UserProfileModel.fromJson(response.data, userId));
    } on DioException catch (e) {
      // Auto-migrate: if API returns 404, try Firestore and create on API
      if (e.response?.statusCode == 404) {
        return _migrateProfileFromFirestore(userId);
      }
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Auto-migration: fetch profile from Firestore, create it on API, return it
  Future<Either<Failure, UserProfile>> _migrateProfileFromFirestore(
      String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Profile doesn't exist anywhere - create a minimal one from Firebase Auth
        final user = firebaseAuth.currentUser;
        if (user != null && user.uid == userId) {
          final profile = UserProfileModel(
            id: user.uid,
            email: user.email ?? '',
            artisticName:
                user.displayName ?? user.email?.split('@')[0] ?? 'Usuário',
            pixKey: '',
            photoUrl: user.photoURL,
          );
          try {
            await apiService.post('/profile', data: profile.toApiJson());
          } catch (_) {}
          return Right(profile);
        }
        return Left(ServerFailure('Perfil não encontrado'));
      }

      // Found in Firestore - migrate to API
      final profile = UserProfileModel.fromJson(doc.data()!, doc.id);
      debugPrint('Auto-migrating profile from Firestore to API for $userId');

      try {
        await apiService.post('/profile', data: profile.toApiJson());
        debugPrint('Profile auto-migration successful for $userId');
      } catch (e) {
        debugPrint('Profile auto-migration to API failed: $e');
        // Still return the Firestore profile even if API write fails
      }

      return Right(profile);
    } catch (e) {
      return Left(ServerFailure('Migration failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UserProfile>>> getProfiles(
      List<String> userIds) async {
    // Batch fetch not implemented in API yet
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> updateProfile(UserProfile profile) async {
    try {
      final model = UserProfileModel(
        id: profile.id,
        email: profile.email,
        artisticName: profile.artisticName,
        nickname: profile.nickname,
        searchName: profile.searchName,
        pixKey: profile.pixKey,
        photoUrl: profile.photoUrl,
        bio: profile.bio,
        instagramUrl: profile.instagramUrl,
        youtubeUrl: profile.youtubeUrl,
        facebookUrl: profile.facebookUrl,
        galleryUrls: profile.galleryUrls,
        fcmToken: profile.fcmToken,
        isLive: profile.isLive,
        liveUntil: profile.liveUntil,
        scheduledShows: profile.scheduledShows,
        birthDate: profile.birthDate,
        verificationLevel: profile.verificationLevel,
        isParentalConsentGranted: profile.isParentalConsentGranted,
        isDobVisible: profile.isDobVisible,
        isPixVisible: profile.isPixVisible,
        followersCount: profile.followersCount,
        followingCount: profile.followingCount,
        unreadMessagesCount: profile.unreadMessagesCount,
        profileViewsCount: profile.profileViewsCount,
        showProfessionalBadge: profile.showProfessionalBadge,
      );

      await apiService.post('/profile', data: model.toApiJson());

      // Dual-write: sync isLive to Firestore for real-time reads by visitors
      await FirebaseFirestore.instance
          .collection('users')
          .doc(profile.id)
          .set({
        'isLive': profile.isLive,
        'liveUntil': profile.liveUntil,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'photoUrl': profile.photoUrl,
        'artisticName': profile.artisticName,
        'nickname': profile.nickname,
        'bio': profile.bio,
      }, SetOptions(merge: true));

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // --- STUBS OR LEGACY DELEGATION ---

  @override
  Future<Either<Failure, void>> updateLastActive(String userId) async {
    // API should handle this implicitly or explicitly
    return const Right(null); // No-op for now
  }

  @override
  Future<Either<Failure, void>> setLiveStatus(
      String userId, bool isLive) async {
    // TODO: Implement API endpoint
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> followUser(
      String currentUserId, String targetUserId) async {
    // TODO: Implement API endpoint
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> unfollowUser(
      String currentUserId, String targetUserId) async {
    // TODO: Implement API endpoint
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<String>>> getFollowedUsers(String userId) async {
    // TODO: Implement API endpoint
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> logProfileVisit(
      {required String viewedUserId,
      required String viewerId,
      required String viewerName,
      String? viewerPhotoUrl}) async {
    // TODO: Implement API endpoint
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getProfileVisitors(
      String userId) async {
    // TODO: Implement API endpoint
    return const Right([]);
  }

  UserEntity _mapFirebaseUser(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Usuário',
      photoUrl: user.photoURL,
    );
  }
}
