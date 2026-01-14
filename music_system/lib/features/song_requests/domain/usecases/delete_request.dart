import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/song_request_repository.dart';

class DeleteRequestParams {
  final String requestId;

  DeleteRequestParams({required this.requestId});
}

class DeleteRequest implements UseCase<void, DeleteRequestParams> {
  final SongRequestRepository repository;

  DeleteRequest(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteRequestParams params) async {
    return await repository.deleteRequest(params.requestId);
  }
}
