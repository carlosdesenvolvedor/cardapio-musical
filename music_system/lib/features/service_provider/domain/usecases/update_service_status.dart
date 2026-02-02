import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_entity.dart';
import '../repositories/service_provider_repository.dart';

class UpdateServiceStatus {
  final IServiceProviderRepository repository;

  UpdateServiceStatus(this.repository);

  Future<Either<Failure, void>> call(UpdateServiceStatusParams params) async {
    return await repository.updateServiceStatus(
      providerId: params.providerId,
      serviceId: params.serviceId,
      status: params.status,
    );
  }
}

class UpdateServiceStatusParams {
  final String providerId;
  final String serviceId;
  final ServiceStatus status;

  UpdateServiceStatusParams({
    required this.providerId,
    required this.serviceId,
    required this.status,
  });
}
