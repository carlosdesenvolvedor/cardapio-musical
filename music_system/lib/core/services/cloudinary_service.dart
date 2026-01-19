import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  final String _cloudName = 'dhje7haru';
  final String _uploadPreset = 'music_system_prese';

  Future<String?> uploadMedia({
    required Uint8List fileBytes,
    required String fileName,
    required String mediaType, // 'image' or 'video'
  }) async {
    try {
      print('Cloudinary: Iniciando upload de $mediaType para $_cloudName');

      // Resource type needs to be part of the URL: image/upload or video/upload
      var uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$mediaType/upload',
      );
      var request = http.MultipartRequest('POST', uri);

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: mediaType == 'video'
            ? MediaType('video', 'mp4')
            : MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);
      request.fields['upload_preset'] = _uploadPreset;

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = utf8.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseString);
        print('Cloudinary: Upload de $mediaType realizado com sucesso!');
        return jsonResponse['secure_url'];
      } else {
        print('Cloudinary: Erro ${response.statusCode}: $responseString');
        return null;
      }
    } catch (e) {
      print('Cloudinary: Exceção durante upload: $e');
      return null;
    }
  }

  Future<String?> uploadImage(Uint8List fileBytes, String fileName) async {
    return uploadMedia(
      fileBytes: fileBytes,
      fileName: fileName,
      mediaType: 'image',
    );
  }

  Future<String?> uploadVideo(Uint8List fileBytes, String fileName) async {
    return uploadMedia(
      fileBytes: fileBytes,
      fileName: fileName,
      mediaType: 'video',
    );
  }
}
