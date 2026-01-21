import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/band_entity.dart';
import '../repositories/band_repository.dart';

class CreateBand implements UseCase<String, BandEntity> {
  final BandRepository repository;

  CreateBand(this.repository);

  @override
  Future<Either<Failure, String>> call(BandEntity band) async {
    return await repository.createBand(band);
  }
}
