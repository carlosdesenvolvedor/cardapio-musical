import '../../../../core/services/backend_api_service.dart';
import '../models/service_model.dart';
import '../../domain/entities/service_entity.dart';

abstract class IServiceProviderRemoteDataSource {
  Future<void> registerService(ServiceModel service);
  Future<List<ServiceModel>> getServices(String providerId);
  Future<void> updateServiceStatus({
    required String providerId,
    required String serviceId,
    required ServiceStatus status,
  });
  Future<void> deleteService({
    required String providerId,
    required String serviceId,
  });
  Future<void> updateService(ServiceModel service);
}

class ServiceProviderRemoteDataSourceImpl
    implements IServiceProviderRemoteDataSource {
  final BackendApiService apiService;

  ServiceProviderRemoteDataSourceImpl({required this.apiService});

  @override
  Future<void> registerService(ServiceModel service) async {
    try {
      print('BACKEND DEBUG: Registrando serviço via API C#');
      await apiService.registerService(service.toJson());
      print('BACKEND DEBUG: Registro concluído com sucesso');
    } catch (e) {
      print('BACKEND ERROR: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<List<ServiceModel>> getServices(String providerId) async {
    try {
      print('BACKEND DEBUG: Buscando serviços para providerId: $providerId');
      final list = await apiService.getServices(providerId);

      print('BACKEND DEBUG: ${list.length} serviços encontrados');
      return list.map((json) {
        final id = json['id'] ?? '';
        return ServiceModel.fromJson(json, id);
      }).toList();
    } catch (e) {
      print('BACKEND ERROR: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> updateServiceStatus({
    required String providerId,
    required String serviceId,
    required ServiceStatus status,
  }) async {
    try {
      print('BACKEND DEBUG: Atualizando status via API C#');
      await apiService.updateServiceStatus(
        serviceId: serviceId,
        status: status.toString().split('.').last,
      );
      print('BACKEND DEBUG: Status atualizado com sucesso');
    } catch (e) {
      print('BACKEND ERROR: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> deleteService({
    required String providerId,
    required String serviceId,
  }) async {
    try {
      print('BACKEND DEBUG: Deletando serviço via API C#');
      await apiService.deleteService(
        serviceId: serviceId,
      );
      print('BACKEND DEBUG: Serviço deletado com sucesso');
    } catch (e) {
      print('BACKEND ERROR: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> updateService(ServiceModel service) async {
    try {
      print('BACKEND DEBUG: Atualizando serviço via API C#');
      await apiService.updateService(service.toJson());
      print('BACKEND DEBUG: Serviço atualizado com sucesso');
    } catch (e) {
      print('BACKEND ERROR: ${e.toString()}');
    }
  }
}
