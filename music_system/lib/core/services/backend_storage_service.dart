import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class BackendStorageService {
  // Use 10.0.2.2 for Android Emulator, localhost for Web/iOS Simulator.
  // Ideally this should be in an environment config.
  static const String baseUrl = 'https://136.248.64.90.nip.io/api/storage';
  final Dio _dio = Dio();

  Future<String> uploadBytes(
      List<int> bytes, String fileName, String folder) async {
    // Auto-compress images
    List<int> processedBytes = bytes;
    if (!kIsWeb &&
        (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg') ||
            fileName.toLowerCase().endsWith('.png'))) {
      processedBytes = await compute(_compressImage, bytes);
    }

    final fileSize = processedBytes.length;
    const int chunkSize = 5 * 1024 * 1024; // 5MB

    if (fileSize < chunkSize) {
      return _uploadSimpleBytes(processedBytes, fileName, folder);
    } else {
      return _uploadMultipartBytes(processedBytes, fileName, folder, chunkSize);
    }
  }

  static List<int> _compressImage(List<int> bytes) {
    img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) return bytes;

    // Resize to max 1080px
    if (image.width > 1080 || image.height > 1080) {
      if (image.width > image.height) {
        image = img.copyResize(image, width: 1080);
      } else {
        image = img.copyResize(image, height: 1080);
      }
    }

    return img.encodeJpg(image, quality: 85);
  }

  Future<String> _uploadSimpleBytes(
      List<int> bytes, String fileName, String folder) async {
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '$baseUrl/upload',
      data: formData,
      queryParameters: {'folder': folder},
    );
    print('DEBUG: BackendStorageService upload response: ${response.data}');
    if (response.statusCode == 200) {
      return response.data['path'];
    } else {
      throw Exception('Upload failed: ${response.statusMessage}');
    }
  }

  Future<String> _uploadMultipartBytes(
      List<int> bytes, String fileName, String folder, int chunkSize) async {
    final fileSize = bytes.length;

    // 1. Start
    final startResponse = await _dio.post(
      '$baseUrl/multipart/start',
      queryParameters: {
        'fileName': fileName,
        'folder': folder,
      },
    );
    final String key = startResponse.data['key'];
    final String uploadId = startResponse.data['uploadId'];

    // 2. Upload Parts
    List<Map<String, dynamic>> parts = [];
    int partNumber = 1;
    int offset = 0;

    while (offset < fileSize) {
      int thisChunkSize = chunkSize;
      if (offset + thisChunkSize > fileSize) {
        thisChunkSize = fileSize - offset;
      }

      final chunkBytes = bytes.sublist(offset, offset + thisChunkSize);

      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          chunkBytes,
          filename: 'part$partNumber',
        ),
      });

      final partResponse = await _dio.post(
        '$baseUrl/multipart/part',
        queryParameters: {
          'Key': key,
          'UploadId': uploadId,
          'PartNumber': partNumber,
        },
        data: formData,
      );

      parts.add({
        "PartNumber": partNumber,
        "ETag": partResponse.data['ETag'],
      });

      offset += thisChunkSize;
      partNumber++;
    }

    // 3. Complete
    final completeResponse = await _dio.post(
      '$baseUrl/complete',
      data: {
        "Key": key,
        "UploadId": uploadId,
        "Parts": parts,
      },
    );

    print(
        'DEBUG: BackendStorageService complete response: ${completeResponse.data}');
    if (completeResponse.statusCode == 200) {
      return completeResponse.data['path'];
    } else {
      throw Exception('Multipart completion failed');
    }
  }

  Future<String> uploadFile(File file, String folder) async {
    final bytes = await file.readAsBytes();
    return uploadBytes(bytes, file.path.split('/').last, folder);
  }
}
