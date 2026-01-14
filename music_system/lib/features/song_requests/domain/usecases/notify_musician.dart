import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/song_request_repository.dart';

class NotifyMusician {
  final SongRequestRepository repository;

  NotifyMusician(this.repository);

  Future<Either<Failure, void>> call(NotifyMusicianParams params) async {
    return await repository.notifyMusician(params.musicianId, params.songName);
  }
}

class NotifyMusicianParams {
  final String musicianId;
  final String songName;

  NotifyMusicianParams({required this.musicianId, required this.songName});
}
