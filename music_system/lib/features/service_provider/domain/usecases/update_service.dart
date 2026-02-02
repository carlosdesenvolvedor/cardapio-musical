import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_entity.dart';
import '../repositories/service_provider_repository.dart';

class UpdateService {
  final IServiceProviderRepository repository;

  UpdateService(this.repository);

  Future<Either<Failure, void>> call(ServiceEntity service) async {
    return await repository.updateService(service);
  }
}
