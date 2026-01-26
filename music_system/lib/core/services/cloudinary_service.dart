import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  final String _cloudName = 'dhje7haru';
  final String _uploadPreset = 'music_system_prese';
  final Dio _dio = Dio();

  Future<String?> uploadMedia({
    required Uint8List fileBytes,
    required String fileName,
    required String mediaType, // 'image' or 'video'
    void Function(double)? onProgress,
  }) async {
    try {
      debugPrint('Cloudinary: Iniciando upload real de $mediaType via Dio');

      final url =
          'https://api.cloudinary.com/v1_1/$_cloudName/$mediaType/upload';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
        'upload_preset': _uploadPreset,
      });

      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1 && onProgress != null) {
            final progress = sent / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Cloudinary: Upload de $mediaType realizado com sucesso!');
        return response.data['secure_url'];
      } else {
        debugPrint('Cloudinary: Erro ${response.statusCode}: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary: Exceção durante upload Dio: $e');
      return null;
    }
  }

  Future<String?> uploadImage(
    Uint8List fileBytes,
    String fileName, {
    void Function(double)? onProgress,
  }) async {
    return uploadMedia(
      fileBytes: fileBytes,
      fileName: fileName,
      mediaType: 'image',
      onProgress: onProgress,
    );
  }

  Future<String?> uploadVideo(
    Uint8List fileBytes,
    String fileName, {
    void Function(double)? onProgress,
  }) async {
    return uploadMedia(
      fileBytes: fileBytes,
      fileName: fileName,
      mediaType: 'video',
      onProgress: onProgress,
    );
  }
}
