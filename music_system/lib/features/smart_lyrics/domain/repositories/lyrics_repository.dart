import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lyrics.dart';

abstract class LyricsRepository {
  Future<Either<Failure, Lyrics>> getLyrics(String songName, String artist);
}
