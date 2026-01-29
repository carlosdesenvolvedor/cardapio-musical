import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({required this.firebaseAuth, required this.firestore});

  @override
  Future<Either<Failure, UserEntity>> signIn(
    String email,
    String password,
  ) async {
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
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '108435262492-m6as6h713s53k329be92bafmhm88an6g.apps.googleusercontent.com'
            : null,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return Left(ServerFailure('Login cancelado pelo usuário'));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return Left(ServerFailure('Erro ao obter usuário do Google'));
      }

      final user = userCredential.user!;

      // Garantir criação do perfil no Firestore
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        final profile = UserProfileModel(
          id: user.uid,
          email: user.email ?? '',
          artisticName:
              user.displayName ?? user.email?.split('@')[0] ?? 'Usuário',
          pixKey: '', // Inicializar como vazio
          photoUrl: user.photoURL,
          followersCount: 0,
          followingCount: 0,
          profileViewsCount: 0,
          isLive: false,
          verificationLevel: VerificationLevel.none,
        );
        await firestore.collection('users').doc(user.uid).set(profile.toJson());
      }

      return Right(_mapFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return Left(
          ServerFailure(e.message ?? 'Erro na autenticação com Google'));
    } catch (e) {
      if (e.toString().contains('popup_closed_by_user')) {
        return Left(ServerFailure('Janela de login fechada pelo usuário'));
      }
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);

      // Create profile document in Firestore
      final profile = UserProfileModel(
        id: user.uid,
        email: user.email ?? '',
        artisticName: name,
        pixKey: '',
        followersCount: 0,
        followingCount: 0,
        profileViewsCount: 0,
        isLive: false,
        verificationLevel: VerificationLevel.none,
      );
      await firestore.collection('users').doc(user.uid).set(profile.toJson());

      // Force token refresh to ensure context-aware services (FCM, Firestore Rules)
      // see the new user session immediately.
      try {
        await user.getIdToken(true);
      } catch (e) {
        debugPrint('Non-critical: Token refresh failed in signUp: $e');
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
    try {
      await firebaseAuth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      return Right(_mapFirebaseUser(user));
    }
    return const Right(null);
  }

  @override
  Stream<UserEntity?> get authStateChanges => firebaseAuth
      .authStateChanges()
      .map((user) => user != null ? _mapFirebaseUser(user) : null);

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return Right(UserProfileModel.fromJson(doc.data()!, doc.id));
      } else {
        return Left(ServerFailure('Perfil não encontrado'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserProfile>>> getProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const Right([]);
    try {
      // O Firestore permite no máximo 30 IDs no 'whereIn'.
      final limitedIds = userIds.take(30).toList();

      final query = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: limitedIds)
          .get();

      final profiles = query.docs
          .map((doc) => UserProfileModel.fromJson(doc.data(), doc.id))
          .toList();

      return Right(profiles);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
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
      );

      final data = model.toJson();
      // Only keep fields that are not null to avoid overwriting with null unless intended
      data.removeWhere(
        (key, value) => value == null && key != 'photoUrl' && key != 'bio',
      );

      await firestore
          .collection('users')
          .doc(profile.id)
          .set(data, SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastActive(String userId) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      // Falhas ao atualizar status online não devem bloquear o app, mas podemos logar
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setLiveStatus(
      String userId, bool isLive) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isLive': isLive,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  UserEntity _mapFirebaseUser(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Usuário',
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<Either<Failure, void>> followUser(
      String currentUserId, String targetUserId) async {
    try {
      final batch = firestore.batch();

      // Adiciona na subcoleção 'following' do usuário atual
      final followingRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      batch.set(followingRef, {
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Opcional: Adicionar na subcoleção 'followers' do alvo (para contagem)
      final followersRef = firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      batch.set(followersRef, {
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Garantir que os contadores sejam incrementados usando merge no set caso o doc não exista
      // Mas aqui usamos a referência direta se soubermos que o doc existe (ou criamos se não existe)
      final userRef = firestore.collection('users').doc(currentUserId);
      final targetRef = firestore.collection('users').doc(targetUserId);

      batch.set(userRef, {'followingCount': FieldValue.increment(1)},
          SetOptions(merge: true));
      batch.set(targetRef, {'followersCount': FieldValue.increment(1)},
          SetOptions(merge: true));

      await batch.commit();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unfollowUser(
      String currentUserId, String targetUserId) async {
    try {
      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .delete();

      await firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .delete();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFollowedUsers(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      final followingIds = snapshot.docs.map((doc) => doc.id).toList();
      return Right(followingIds);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logProfileVisit({
    required String viewedUserId,
    required String viewerId,
    required String viewerName,
    String? viewerPhotoUrl,
  }) async {
    try {
      final batch = firestore.batch();

      // Referência para o documento na subcoleção 'profile_views'
      // Usamos o ID do visitante como ID do documento para que cada pessoa conte apenas uma vez (ou atualize o timestamp)
      // Se quiser contar CADA visita, use .add(). Mas geralmente redes sociais mostram "Quem te visitou" de forma única.
      final visitRef = firestore
          .collection('users')
          .doc(viewedUserId)
          .collection('profile_views')
          .doc(viewerId);

      batch.set(visitRef, {
        'viewerId': viewerId,
        'viewerName': viewerName,
        'viewerPhotoUrl': viewerPhotoUrl,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      // Incrementa o contador global do perfil
      final userRef = firestore.collection('users').doc(viewedUserId);
      batch.update(userRef, {'profileViewsCount': FieldValue.increment(1)});

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getProfileVisitors(
      String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('profile_views')
          .orderBy('viewedAt', descending: true)
          .limit(50)
          .get();

      final visitors = snapshot.docs.map((doc) => doc.data()).toList();
      return Right(visitors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
