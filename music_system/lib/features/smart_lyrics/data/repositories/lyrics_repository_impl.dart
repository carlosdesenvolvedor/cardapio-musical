import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../datasources/lyrics_remote_data_source.dart';

class LyricsRepositoryImpl implements LyricsRepository {
  final LyricsRemoteDataSource remoteDataSource;

  LyricsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Lyrics>> getLyrics(String songName, String artist) async {
    try {
      final lyrics = await remoteDataSource.fetchLyrics(songName, artist);
      return Right(lyrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
