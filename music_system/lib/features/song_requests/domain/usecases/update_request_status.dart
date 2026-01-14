import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/song_request_repository.dart';

class UpdateRequestStatusParams {
  final String requestId;
  final String status;

  UpdateRequestStatusParams({required this.requestId, required this.status});
}

class UpdateRequestStatus implements UseCase<void, UpdateRequestStatusParams> {
  final SongRequestRepository repository;

  UpdateRequestStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateRequestStatusParams params) async {
    return await repository.updateRequestStatus(params.requestId, params.status);
  }
}
