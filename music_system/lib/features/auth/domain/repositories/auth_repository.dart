import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  Future<Either<Failure, UserEntity>> signUp(
    String email,
    String password,
    String name,
  );
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
  Future<Either<Failure, UserProfile>> getProfile(String userId);
  Future<Either<Failure, void>> updateProfile(UserProfile profile);
  Future<Either<Failure, void>> updateLastActive(String userId);
}
