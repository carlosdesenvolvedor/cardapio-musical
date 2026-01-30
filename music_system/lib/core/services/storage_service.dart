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
      print('DEBUG: Starting upload for $fileName ($contentType)...');
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask task = ref.putData(
        fileBytes,
        SettableMetadata(contentType: contentType),
      );

      final TaskSnapshot snapshot = await task;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('DEBUG: Upload successful! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Firebase Storage Error during upload of $fileName: $e');
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
