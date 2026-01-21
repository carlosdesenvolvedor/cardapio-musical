import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class LogProfileView {
  final AuthRepository repository;

  LogProfileView(this.repository);

  Future<Either<Failure, void>> call({
    required String viewedUserId,
    required String viewerId,
    required String viewerName,
    String? viewerPhotoUrl,
  }) async {
    return await repository.logProfileVisit(
      viewedUserId: viewedUserId,
      viewerId: viewerId,
      viewerName: viewerName,
      viewerPhotoUrl: viewerPhotoUrl,
    );
  }
}
