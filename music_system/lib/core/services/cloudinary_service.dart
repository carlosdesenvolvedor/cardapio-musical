import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  final String _cloudName = 'dhje7haru';
  // Nome exato conforme seu print: music_system_prese
  final String _uploadPreset = 'music_system_prese'; 

  Future<String?> uploadImage(Uint8List fileBytes, String fileName) async {
    try {
      print('Cloudinary: Iniciando upload para $_cloudName usando preset $_uploadPreset');
      
      var uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      var request = http.MultipartRequest('POST', uri);
      
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);
      request.fields['upload_preset'] = _uploadPreset;

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = utf8.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseString);
        print('Cloudinary: Upload realizado com sucesso!');
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
}
