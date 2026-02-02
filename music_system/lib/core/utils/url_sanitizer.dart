class UrlSanitizer {
  static const String serverIp = 'localhost';

  static String sanitize(String url) {
    if (url.isEmpty) return url;

    // Replace internal docker names or remote IPs with localhost
    // Use Regex with word boundaries to match the IP specifically as a hostname
    final ipRegex = RegExp(r'136\.248\.64\.90(\.nip\.io)?(:\d+)?');

    String sanitized = url
        .replaceFirst(
            'http://minio:9000/music-system-media/', 'http://$serverIp/media/')
        .replaceFirst(
            'minio:9000/music-system-media/', 'http://$serverIp/media/')
        .replaceAll(ipRegex, serverIp)
        .replaceAll('137.131.245.169', serverIp)
        .replaceAll('137.131.245.16', serverIp)
        .replaceAll('140.238.191.244', serverIp)
        .replaceFirst(
            'https://localhost', 'http://localhost') // Force HTTP locally
        .replaceFirst('localhost:5000', serverIp)
        .replaceFirst('127.0.0.1:5000', serverIp);

    return sanitized;
  }
}
