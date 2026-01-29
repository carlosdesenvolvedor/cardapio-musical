class UrlSanitizer {
  static const String serverIp = '136.248.64.90.nip.io';

  static String sanitize(String url) {
    if (url.isEmpty) return url;

    // Replace internal docker names with public IP
    // Also handle cases without http:// if they appear
    String sanitized = url
        .replaceFirst(
            'http://minio:9000/music-system-media/', 'https://$serverIp/media/')
        .replaceFirst(
            'minio:9000/music-system-media/', 'https://$serverIp/media/')
        .replaceAll('137.131.245.169', serverIp)
        .replaceAll('136.248.64.90', serverIp)
        .replaceAll('137.131.245.16', serverIp)
        .replaceAll('140.238.191.244', serverIp)
        .replaceFirst('http://', 'https://') // Force HTTPS on internal strings
        .replaceFirst('localhost:5000', serverIp)
        .replaceFirst('127.0.0.1:5000', serverIp);

    return sanitized;
  }
}
