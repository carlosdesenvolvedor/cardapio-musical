import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/repertoire_repository.dart';

class ImportRepertoire implements UseCase<void, ImportRepertoireParams> {
  final RepertoireRepository repository;

  ImportRepertoire(this.repository);

  @override
  Future<Either<Failure, void>> call(ImportRepertoireParams params) async {
    return await repository.importFromExcel(params.fileBytes, params.musicianId);
  }
}

class ImportRepertoireParams {
  final Uint8List fileBytes;
  final String musicianId;

  ImportRepertoireParams({required this.fileBytes, required this.musicianId});
}
