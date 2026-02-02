import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_provider_repository.dart';
import '../datasources/service_provider_remote_data_source.dart';
import '../models/service_model.dart';

class ServiceProviderRepositoryImpl implements IServiceProviderRepository {
  final IServiceProviderRemoteDataSource remoteDataSource;

  ServiceProviderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> registerService(ServiceEntity service) async {
    try {
      final serviceModel = ServiceModel(
        id: service.id,
        providerId: service.providerId,
        name: service.name,
        description: service.description,
        category: service.category,
        basePrice: service.basePrice,
        priceDescription: service.priceDescription,
        status: service.status,
        technicalDetails: service.technicalDetails,
        createdAt: service.createdAt,
      );
      await remoteDataSource.registerService(serviceModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server Failure'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices(
      String providerId) async {
    try {
      final services = await remoteDataSource.getServices(providerId);
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server Failure'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateServiceStatus({
    required String providerId,
    required String serviceId,
    required ServiceStatus status,
  }) async {
    try {
      await remoteDataSource.updateServiceStatus(
        providerId: providerId,
        serviceId: serviceId,
        status: status,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server Failure'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteService({
    required String providerId,
    required String serviceId,
  }) async {
    try {
      await remoteDataSource.deleteService(
        providerId: providerId,
        serviceId: serviceId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server Failure'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateService(ServiceEntity service) async {
    try {
      final serviceModel = ServiceModel(
        id: service.id,
        providerId: service.providerId,
        name: service.name,
        description: service.description,
        category: service.category,
        basePrice: service.basePrice,
        priceDescription: service.priceDescription,
        status: service.status,
        technicalDetails: service.technicalDetails,
        createdAt: service.createdAt,
      );
      await remoteDataSource.updateService(serviceModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server Failure'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
