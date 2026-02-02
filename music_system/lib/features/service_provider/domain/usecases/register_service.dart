import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/service_entity.dart';
import '../repositories/service_provider_repository.dart';

class RegisterService implements UseCase<void, ServiceEntity> {
  final IServiceProviderRepository repository;

  RegisterService(this.repository);

  @override
  Future<Either<Failure, void>> call(ServiceEntity params) async {
    return await repository.registerService(params);
  }
}
