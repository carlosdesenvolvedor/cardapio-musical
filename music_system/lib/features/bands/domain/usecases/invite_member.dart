import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/band_member_entity.dart';
import '../repositories/band_repository.dart';

class InviteMemberParams {
  final String bandId;
  final BandMemberEntity member;

  InviteMemberParams({required this.bandId, required this.member});
}

class InviteMember implements UseCase<void, InviteMemberParams> {
  final BandRepository repository;

  InviteMember(this.repository);

  @override
  Future<Either<Failure, void>> call(InviteMemberParams params) async {
    return await repository.inviteMember(params.bandId, params.member);
  }
}
