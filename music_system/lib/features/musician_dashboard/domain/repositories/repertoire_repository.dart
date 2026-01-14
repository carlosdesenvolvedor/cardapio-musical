import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

import '../../../client_menu/domain/entities/song.dart';

abstract class RepertoireRepository {
  Future<Either<Failure, void>> importFromExcel(Uint8List fileBytes, String musicianId);
  Future<Either<Failure, void>> addSong(Song song);
  Future<Either<Failure, List<Song>>> getSongs(String musicianId);
  Future<Either<Failure, void>> updateSong(Song song);
  Future<Either<Failure, void>> deleteSong(String songId);
}
