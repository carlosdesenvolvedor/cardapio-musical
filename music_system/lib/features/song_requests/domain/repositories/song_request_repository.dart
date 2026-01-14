import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/song_request.dart';

abstract class SongRequestRepository {
  Future<Either<Failure, void>> createRequest(SongRequest request);
  Stream<Either<Failure, List<SongRequest>>> streamRequests(String musicianId);
  Future<Either<Failure, void>> updateRequestStatus(String requestId, String status);
  Future<Either<Failure, void>> notifyMusician(String musicianId, String songName);
  Future<Either<Failure, void>> deleteRequest(String requestId);
}
