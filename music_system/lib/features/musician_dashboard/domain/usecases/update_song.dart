import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../client_menu/domain/entities/song.dart';
import '../repositories/repertoire_repository.dart';

class UpdateSong implements UseCase<void, Song> {
  final RepertoireRepository repository;

  UpdateSong(this.repository);

  @override
  Future<Either<Failure, void>> call(Song song) async {
    return await repository.updateSong(song);
  }
}
