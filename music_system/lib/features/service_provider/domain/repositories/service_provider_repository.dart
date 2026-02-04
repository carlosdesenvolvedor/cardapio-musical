import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_entity.dart';

abstract class IServiceProviderRepository {
  Future<Either<Failure, void>> registerService(ServiceEntity service);
  Future<Either<Failure, List<ServiceEntity>>> getServices(String providerId);
  Future<Either<Failure, List<ServiceEntity>>> getAllServices();
  Future<Either<Failure, void>> updateServiceStatus({
    required String providerId,
    required String serviceId,
    required ServiceStatus status,
  });
  Future<Either<Failure, void>> deleteService({
    required String providerId,
    required String serviceId,
  });
  Future<Either<Failure, void>> updateService(ServiceEntity service);
}
