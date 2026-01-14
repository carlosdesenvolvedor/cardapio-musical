import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/song_request.dart';
import '../repositories/song_request_repository.dart';

class CreateRequest implements UseCase<void, SongRequest> {
  final SongRequestRepository repository;

  CreateRequest(this.repository);

  @override
  Future<Either<Failure, void>> call(SongRequest params) async {
    final result = await repository.createRequest(params);
    return await result.fold(
      (failure) async => Left(failure),
      (_) async {
        // Trigger notification after request is created
        await repository.notifyMusician(params.musicianId, params.songName);
        return const Right(null);
      },
    );
  }
}
