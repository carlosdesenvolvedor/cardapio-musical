import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(Uint8List fileBytes, String fileName) async {
    try {
      if (kDebugMode) {
        print('Iniciando upload para o Firebase Storage via Base64 (Web Workaround)...');
      }

      // Create a unique file name to avoid collisions
      final String extension = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final String uniqueName = '${const Uuid().v4()}.$extension';
      
      final Reference ref = _storage.ref().child('uploads').child(uniqueName);
      
      // On Web, sometimes putData/putBlob fails due to CORS if not configured.
      // Using uploadString with base64 can sometimes be more stable on localhost.
      final String base64String = base64Encode(fileBytes);
      
      final UploadTask task = ref.putString(
        base64String,
        format: PutStringFormat.base64,
        metadata: SettableMetadata(contentType: 'image/$extension'),
      );

      // Listen to progress
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = 100 * (snapshot.bytesTransferred / snapshot.totalBytes);
        if (kDebugMode) {
          print('Upload progress: ${progress.toStringAsFixed(2)}%');
        }
      });
      
      // Wait for completion with a long timeout
      final TaskSnapshot snapshot = await task.timeout(
        const Duration(seconds: 60),
      );
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('Upload concluído com sucesso: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      print('Firebase Storage Error (Refined): $e');
      // If base64 fails too, it's definitely CORS or Rules.
      rethrow;
    }
  }
}
