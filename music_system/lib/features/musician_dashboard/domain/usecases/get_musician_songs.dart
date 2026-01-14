import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../client_menu/domain/entities/song.dart';
import '../repositories/repertoire_repository.dart';

class GetMusicianSongs implements UseCase<List<Song>, String> {
  final RepertoireRepository repository;

  GetMusicianSongs(this.repository);

  @override
  Future<Either<Failure, List<Song>>> call(String musicianId) async {
    return await repository.getSongs(musicianId);
  }
}
