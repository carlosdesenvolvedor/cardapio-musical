import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/service_provider_repository.dart';

class DeleteService {
  final IServiceProviderRepository repository;

  DeleteService(this.repository);

  Future<Either<Failure, void>> call(DeleteServiceParams params) async {
    return await repository.deleteService(
      providerId: params.providerId,
      serviceId: params.serviceId,
    );
  }
}

class DeleteServiceParams {
  final String providerId;
  final String serviceId;

  DeleteServiceParams({
    required this.providerId,
    required this.serviceId,
  });
}
