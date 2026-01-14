import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/song.dart';
import '../repositories/song_repository.dart';

class GetSongs implements UseCase<List<Song>, String> {
  final SongRepository repository;

  GetSongs(this.repository);

  @override
  Future<Either<Failure, List<Song>>> call(String musicianId) async {
    return await repository.getSongs(musicianId);
  }
}
