import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask task = ref.putData(
        fileBytes,
        SettableMetadata(contentType: contentType),
      );

      final TaskSnapshot snapshot = await task.timeout(
        const Duration(seconds: 120),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Firebase Storage Error: $e');
      rethrow;
    }
  }

  Future<String?> uploadImage(Uint8List fileBytes, String fileName) async {
    return uploadFile(
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: 'image/jpeg',
    );
  }
}
