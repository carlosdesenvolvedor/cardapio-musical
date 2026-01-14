import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
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
  Future<Either<Failure, UserEntity>> signIn(String email, String password) async {
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
  Future<Either<Failure, UserEntity>> signUp(String email, String password, String name) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      return Right(_mapFirebaseUser(credential.user!));
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
  Stream<UserEntity?> get authStateChanges =>
      firebaseAuth.authStateChanges().map((user) => user != null ? _mapFirebaseUser(user) : null);

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
  Future<Either<Failure, void>> updateProfile(UserProfile profile) async {
    try {
      final model = UserProfileModel(
        id: profile.id,
        email: profile.email,
        artisticName: profile.artisticName,
        pixKey: profile.pixKey,
        photoUrl: profile.photoUrl,
        bio: profile.bio,
        instagramUrl: profile.instagramUrl,
        youtubeUrl: profile.youtubeUrl,
        facebookUrl: profile.facebookUrl,
        galleryUrls: profile.galleryUrls,
        fcmToken: profile.fcmToken,
      );

      final data = model.toJson();
      // Only keep fields that are not null to avoid overwriting with null unless intended
      data.removeWhere((key, value) => value == null && key != 'photoUrl' && key != 'bio'); 

      await firestore.collection('users').doc(profile.id).set(data, SetOptions(merge: true));
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
}
