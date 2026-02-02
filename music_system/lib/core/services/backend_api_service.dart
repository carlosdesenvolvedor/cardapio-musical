import 'package:dio/dio.dart';

class BackendApiService {
  static const String baseUrl = 'https://136.248.64.90.nip.io/api/service';
  final Dio _dio;

  BackendApiService(this._dio);

  Future<void> registerService(Map<String, dynamic> serviceJson) async {
    try {
      final response = await _dio.post('$baseUrl/register', data: serviceJson);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Failed to register service: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error registering service: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getServices(String providerId) async {
    try {
      final response = await _dio.get('$baseUrl/list/$providerId');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to fetch services: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

  Future<void> updateServiceStatus({
    required String serviceId,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/status/$serviceId',
        data: {'status': status},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update status: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  Future<void> updateService(Map<String, dynamic> serviceJson) async {
    try {
      final response = await _dio.put('$baseUrl/update', data: serviceJson);
      if (response.statusCode != 200) {
        throw Exception('Failed to update service: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error updating service: $e');
    }
  }

  Future<void> deleteService({
    required String serviceId,
  }) async {
    try {
      final response = await _dio.delete('$baseUrl/$serviceId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete service: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error deleting service: $e');
    }
  }
}
