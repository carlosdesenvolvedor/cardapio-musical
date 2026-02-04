import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/service_entity.dart';
import '../repositories/service_provider_repository.dart';

class GetAllServices implements UseCase<List<ServiceEntity>, NoParams> {
  final IServiceProviderRepository repository;

  GetAllServices(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(NoParams params) async {
    return await repository.getAllServices();
  }
}
