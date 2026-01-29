class UrlSanitizer {
  static const String serverIp = '136.248.64.90';

  static String sanitize(String url) {
    if (url.isEmpty) return url;

    // Replace internal docker names with public IP
    // Also handle cases without http:// if they appear
    String sanitized = url
        .replaceFirst(
            'http://minio:9000/music-system-media/', 'http://$serverIp/media/')
        .replaceFirst(
            'minio:9000/music-system-media/', 'http://$serverIp/media/')
        .replaceFirst('localhost:5000', '$serverIp')
        .replaceFirst('127.0.0.1:5000', '$serverIp');

    return sanitized;
  }
}
