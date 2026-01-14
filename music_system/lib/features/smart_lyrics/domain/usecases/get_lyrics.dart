import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/lyrics.dart';
import '../repositories/lyrics_repository.dart';

class GetLyricsParams {
  final String songName;
  final String artist;

  GetLyricsParams({required this.songName, required this.artist});
}

class GetLyrics implements UseCase<Lyrics, GetLyricsParams> {
  final LyricsRepository repository;

  GetLyrics(this.repository);

  @override
  Future<Either<Failure, Lyrics>> call(GetLyricsParams params) async {
    return await repository.getLyrics(params.songName, params.artist);
  }
}
