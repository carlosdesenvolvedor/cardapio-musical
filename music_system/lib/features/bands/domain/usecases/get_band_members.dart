import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/band_member_entity.dart';
import '../repositories/band_repository.dart';

class GetBandMembers implements UseCase<List<BandMemberEntity>, String> {
  final BandRepository repository;

  GetBandMembers(this.repository);

  @override
  Future<Either<Failure, List<BandMemberEntity>>> call(String bandId) async {
    return await repository.getBandMembers(bandId);
  }
}
