import 'package:flutter/foundation.dart';

class UrlSanitizer {
  static const String serverIp = 'localhost';
  static const String prodHost = '136.248.64.90.nip.io';

  static String sanitize(String url) {
    if (url.isEmpty) return url;

    // Em produção (Web), não devemos forçar localhost nem HTTP
    if (kIsWeb && !kDebugMode) {
      if (url.contains('localhost')) {
        return url
            .replaceFirst('localhost', prodHost)
            .replaceFirst('http://', 'https://');
      }
      return url.replaceFirst('http://', 'https://');
    }

    // Lógica para desenvolvimento local
    final ipRegex = RegExp(r'136\.248\.64\.90(\.nip\.io)?(:\d+)?');

    String sanitized = url
        .replaceFirst(
            'http://minio:9000/music-system-media/', 'http://$serverIp/media/')
        .replaceFirst(
            'minio:9000/music-system-media/', 'http://$serverIp/media/')
        .replaceAll(ipRegex, serverIp)
        .replaceAll('137.131.245.169', serverIp)
        .replaceAll('137.131.245.16', serverIp)
        .replaceAll('140.238.191.244', serverIp);

    // Só força HTTP se estivermos em debug e não for web (ou for web localhost)
    if (kDebugMode &&
        (url.contains('localhost') || url.contains('127.0.0.1'))) {
      // sanitized = sanitized.replaceFirst('https://', 'http://');
    }

    return sanitized;
  }
}
