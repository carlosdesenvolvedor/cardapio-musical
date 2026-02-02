import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/service_entity.dart';
import '../repositories/service_provider_repository.dart';

class GetProviderServices implements UseCase<List<ServiceEntity>, String> {
  final IServiceProviderRepository repository;

  GetProviderServices(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(String providerId) async {
    return await repository.getServices(providerId);
  }
}
