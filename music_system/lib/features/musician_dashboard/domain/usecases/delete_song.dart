import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/repertoire_repository.dart';

class DeleteSong implements UseCase<void, String> {
  final RepertoireRepository repository;

  DeleteSong(this.repository);

  @override
  Future<Either<Failure, void>> call(String songId) async {
    return await repository.deleteSong(songId);
  }
}
