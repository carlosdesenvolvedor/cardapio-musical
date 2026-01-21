import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/band_remote_data_source.dart';
import '../../domain/entities/band_entity.dart';
import '../../domain/entities/band_member_entity.dart';
import '../../domain/repositories/band_repository.dart';
import '../models/band_model.dart';
import '../models/band_member_model.dart';

import '../../../../features/community/domain/repositories/notification_repository.dart';
import '../../../../features/community/domain/entities/notification_entity.dart';
import 'package:uuid/uuid.dart';

class BandRepositoryImpl implements BandRepository {
  final BandRemoteDataSource remoteDataSource;
  final NotificationRepository notificationRepository;

  BandRepositoryImpl({
    required this.remoteDataSource,
    required this.notificationRepository,
  });

  @override
  Future<Either<Failure, String>> createBand(BandEntity band) async {
    try {
      final model = BandModel.fromEntity(band);
      final id = await remoteDataSource.createBand(model);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BandEntity>> getBand(String bandId) async {
    try {
      final band = await remoteDataSource.getBand(bandId);
      return Right(band);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BandEntity>> getBandBySlug(String slug) async {
    try {
      final band = await remoteDataSource.getBandBySlug(slug);
      return Right(band);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BandEntity>>> getUserBands(String userId) async {
    try {
      final bands = await remoteDataSource.getUserBands(userId);
      return Right(bands);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBand(BandEntity band) async {
    try {
      final model = BandModel.fromEntity(band);
      await remoteDataSource.updateBand(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> inviteMember(
      String bandId, BandMemberEntity member) async {
    try {
      final model = BandMemberModel(
        userId: member.userId,
        role: member.role,
        status: member.status,
        instrument: member.instrument,
        userName: member.userName,
        userPhotoUrl: member.userPhotoUrl,
      );
      await remoteDataSource.inviteMember(bandId, model);

      // Trigger notification
      String bandName = 'Uma banda';
      try {
        final band = await remoteDataSource.getBand(bandId);
        bandName = band.name;
      } catch (_) {}

      final notification = NotificationEntity(
        id: const Uuid().v4(),
        recipientId: member.userId,
        senderId: bandId, // Use bandId as sender for context
        senderName: bandName,
        type: NotificationType.band_invite,
        message: 'convidou você para tocar na banda $bandName!',
        createdAt: DateTime.now(),
        isRead: false,
      );
      await notificationRepository.createNotification(notification);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> respondToInvite(
      String bandId, String userId, String status) async {
    try {
      await remoteDataSource.respondToInvite(bandId, userId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BandMemberEntity>>> getBandMembers(
      String bandId) async {
    try {
      final members = await remoteDataSource.getBandMembers(bandId);
      return Right(members);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember(
      String bandId, String userId) async {
    try {
      await remoteDataSource.removeMember(bandId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
