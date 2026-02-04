import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/error/exceptions.dart';
import '../models/service_model.dart';
import '../../domain/entities/service_entity.dart';

abstract class IServiceProviderRemoteDataSource {
  Future<void> registerService(ServiceModel service);
  Future<List<ServiceModel>> getServices(String providerId);
  Future<List<ServiceModel>> getAllServices();
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
  final FirebaseFirestore firestore;

  ServiceProviderRemoteDataSourceImpl({
    required this.apiService,
    required this.firestore,
  });

  @override
  Future<void> registerService(ServiceModel service) async {
    try {
      print('BACKEND DEBUG: Registrando serviço via API C#');
      try {
        await apiService.registerService(service.toJson());
        print('BACKEND DEBUG: Registro na API concluído com sucesso');
      } catch (e) {
        print(
            'BACKEND WARNING: Falha no registro via API, prosseguindo com backup: $e');
      }

      // Always fallback/dual-write to Firestore to ensure availability in contractors global list
      print('BACKEND DEBUG: Sincronizando com Firestore (Top-level services)');
      await firestore
          .collection('services')
          .doc(service.id)
          .set(service.toJson());
      print('BACKEND DEBUG: Backup no Firestore concluído');
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
  Future<List<ServiceModel>> getAllServices() async {
    try {
      print('BACKEND DEBUG: Tentando buscar serviços via API C# (Global)');
      final list = await apiService.getAllServices();
      return list
          .map((json) => ServiceModel.fromJson(json, json['id'] ?? ''))
          .toList();
    } catch (e) {
      print('BACKEND ERROR: API falhou (Erro 405/Outro): $e');
      print('BACKEND DEBUG: Iniciando FALLBACK para Firestore...');

      try {
        final snapshot =
            await firestore.collection('services').limit(100).get();
        final services =
            snapshot.docs.map((doc) => ServiceModel.fromSnapshot(doc)).toList();
        print(
            'BACKEND DEBUG: Fallback concluído. ${services.length} serviços recuperados da coleção global.');
        return services;
      } catch (firestoreError) {
        print(
            'BACKEND ERROR: Fallback do Firestore também falhou: $firestoreError');
        throw ServerException('Erro ao buscar serviços na API e no Firestore.');
      }
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
      try {
        await apiService.updateServiceStatus(
          serviceId: serviceId,
          status: status.toString().split('.').last,
        );
        print('BACKEND DEBUG: Status atualizado na API com sucesso');
      } catch (e) {
        print(
            'BACKEND WARNING: Falha na atualização de status via API, prosseguindo com backup: $e');
      }

      // Sync to Firestore
      print('BACKEND DEBUG: Sincronizando status com Firestore (Top-level)');
      await firestore.collection('services').doc(serviceId).set(
          {'status': status.toString().split('.').last},
          SetOptions(merge: true));
      print('BACKEND DEBUG: Status no Firestore atualizado');
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
      try {
        await apiService.updateService(service.toJson());
        print('BACKEND DEBUG: Atualização na API concluída com sucesso');
      } catch (e) {
        print(
            'BACKEND WARNING: Falha na atualização via API, prosseguindo com backup: $e');
      }

      // Sync to Firestore
      print(
          'BACKEND DEBUG: Sincronizando atualização com Firestore (Top-level)');
      await firestore
          .collection('services')
          .doc(service.id)
          .set(service.toJson());
      print('BACKEND DEBUG: Atualização no Firestore concluída');
    } catch (e) {
      print('BACKEND ERROR: ${e.toString()}');
    }
  }
}
