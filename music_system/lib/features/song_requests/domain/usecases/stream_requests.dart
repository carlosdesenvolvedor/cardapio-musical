import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/song_request.dart';
import '../repositories/song_request_repository.dart';

class StreamRequests {
  final SongRequestRepository repository;

  StreamRequests(this.repository);

  Stream<Either<Failure, List<SongRequest>>> call(String musicianId) {
    return repository.streamRequests(musicianId);
  }
}
