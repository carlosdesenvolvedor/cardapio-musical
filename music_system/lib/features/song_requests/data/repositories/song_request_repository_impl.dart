import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/song_request.dart';
import '../../domain/repositories/song_request_repository.dart';
import '../datasources/song_request_remote_data_source.dart';
import '../models/song_request_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SongRequestRepositoryImpl implements SongRequestRepository {
  final SongRequestRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;
  final PushNotificationService notificationService;

  SongRequestRepositoryImpl({
    required this.remoteDataSource,
    required this.authRepository,
    required this.notificationService,
  });

  @override
  Future<Either<Failure, void>> createRequest(SongRequest request) async {
    try {
      final model = SongRequestModel(
        id: request.id,
        songName: request.songName,
        artistName: request.artistName,
        clientName: request.clientName,
        musicianId: request.musicianId,
        tipAmount: request.tipAmount,
        isCustomRequest: request.isCustomRequest,
        status: request.status,
        createdAt: request.createdAt,
      );
      await remoteDataSource.createRequest(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<SongRequest>>> streamRequests(String musicianId) {
    return remoteDataSource.streamRequests(musicianId).map<Either<Failure, List<SongRequest>>>(
      (requests) => Right(requests),
    ).handleError((error) {
      return Left(ServerFailure(error.toString()));
    });
  }

  @override
  Future<Either<Failure, void>> updateRequestStatus(String requestId, String status) async {
    try {
      await remoteDataSource.updateRequestStatus(requestId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> notifyMusician(String musicianId, String songName) async {
    try {
      final profileResult = await authRepository.getProfile(musicianId);
      return await profileResult.fold(
        (failure) async => Left(failure),
        (profile) async {
          if (profile.fcmToken != null) {
            await notificationService.sendNotification(
              recipientToken: profile.fcmToken!,
              title: 'Novo Pedido! 🎸',
              body: 'Um cliente pediu: $songName',
            );
          }
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRequest(String requestId) async {
    try {
      await remoteDataSource.deleteRequest(requestId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
