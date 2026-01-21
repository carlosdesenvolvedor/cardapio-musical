import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/band_entity.dart';
import '../entities/band_member_entity.dart';

abstract class BandRepository {
  Future<Either<Failure, String>> createBand(BandEntity band);
  Future<Either<Failure, BandEntity>> getBand(String bandId);
  Future<Either<Failure, BandEntity>> getBandBySlug(String slug);
  Future<Either<Failure, List<BandEntity>>> getUserBands(String userId);
  Future<Either<Failure, void>> updateBand(BandEntity band);

  // Member management
  Future<Either<Failure, void>> inviteMember(
      String bandId, BandMemberEntity member);
  Future<Either<Failure, void>> respondToInvite(
      String bandId, String userId, String status);
  Future<Either<Failure, List<BandMemberEntity>>> getBandMembers(String bandId);
  Future<Either<Failure, void>> removeMember(String bandId, String userId);
}
