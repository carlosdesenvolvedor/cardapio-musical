import 'package:dio/dio.dart';

class BackendApiService {
  static const String baseApiUrl = 'https://136.248.64.90.nip.io/api';
  static const String serviceUrl = '$baseApiUrl/service';
  final Dio _dio;

  BackendApiService(this._dio);

  // Generic methods for Phase 3 Migration
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get('$baseApiUrl$path', queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post('$baseApiUrl$path', data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put('$baseApiUrl$path', data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete('$baseApiUrl$path');
  }

  Future<void> registerService(Map<String, dynamic> serviceJson) async {
    try {
      final response =
          await _dio.post('$serviceUrl/register', data: serviceJson);
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
      final response = await _dio.get('$serviceUrl/list/$providerId');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to fetch services: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllServices() async {
    try {
      final response = await _dio.get('$serviceUrl/all');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception(
            'Failed to fetch all services: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching all services: $e');
    }
  }

  Future<void> updateServiceStatus({
    required String serviceId,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '$serviceUrl/status/$serviceId',
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
      final response = await _dio.put('$serviceUrl/update', data: serviceJson);
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
      final response = await _dio.delete('$serviceUrl/$serviceId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete service: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error deleting service: $e');
    }
  }
}
