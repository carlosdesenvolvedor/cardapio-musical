import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/song_remote_data_source.dart';

class SongRepositoryImpl implements SongRepository {
  final SongRemoteDataSource remoteDataSource;

  SongRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Song>>> getSongs(String musicianId) async {
    try {
      final songs = await remoteDataSource.getSongs(musicianId);
      return Right(songs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
