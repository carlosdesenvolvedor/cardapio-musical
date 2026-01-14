import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/song.dart';

abstract class SongRepository {
  Future<Either<Failure, List<Song>>> getSongs(String musicianId);
}
