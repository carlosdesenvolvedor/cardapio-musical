import 'dart:convert';
import 'package:http/http.dart' as http;

class DeezerSong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumCover;
  final String preview;

  DeezerSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumCover,
    required this.preview,
  });

  factory DeezerSong.fromJson(Map<String, dynamic> json) {
    return DeezerSong(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      artist: json['artist']['name'] ?? '',
      album: json['album']['title'] ?? '',
      albumCover: json['album']['cover_medium'] ?? '',
      preview: json['preview'] ?? '',
    );
  }
}

class DeezerService {
  Future<List<DeezerSong>> searchSongs(String query) async {
    if (query.isEmpty) return [];

    // Using a more reliable CORS proxy to bypass browser restrictions on Flutter Web
    final targetUrl =
        'https://api.deezer.com/search?q=${Uri.encodeComponent(query)}';
    final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

    try {
      final response = await http.get(Uri.parse(proxyUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['data'] ?? [];
        return results.map((json) => DeezerSong.fromJson(json)).toList();
      }
    } catch (e) {
      print('Deezer search error: $e');
    }
    return [];
  }
}
