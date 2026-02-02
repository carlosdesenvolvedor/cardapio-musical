import 'package:flutter/foundation.dart';

class CloudinarySanitizer {
  static String sanitize(
    String url, {
    required String mediaType,
    String? filterId,
    double? startOffset,
    double? endOffset,
  }) {
    if (url.startsWith('http://minio:9000/music-system-media/')) {
      url = url.replaceFirst('http://minio:9000/music-system-media/',
          'http://136.248.64.90.nip.io/media/');
    } else if (url.contains('minio:9000/music-system-media/')) {
      url = url.replaceFirst('minio:9000/music-system-media/',
          'http://136.248.64.90.nip.io/media/');
    } else if (url.contains('localhost') || url.contains('127.0.0.1')) {
      url = url.replaceFirst(
          RegExp(r'.*(localhost|127\.0\.0\.1)(:\d+)?/media/'),
          'http://136.248.64.90.nip.io/media/');
      // Handle cases where it was just localhost/api or similar
      if (url.startsWith('http://localhost') ||
          url.startsWith('http://127.0.0.1')) {
        url = url.replaceFirst(
            RegExp(r'http://(localhost|127\.0\.0\.1)(:\d+)?/'),
            'http://136.248.64.90.nip.io/');
      }
    } else if (!url.startsWith('http') &&
        (url.contains('posts/') ||
            url.contains('stories/') ||
            url.contains('avatars/'))) {
      // Prepend production domain if it's just a path
      url = 'http://136.248.64.90.nip.io/media/$url';
    } else if (url.contains('firebasestorage.googleapis.com')) {
      try {
        // Pattern: https://firebasestorage.googleapis.com/v0/b/BUCKET/o/PATH?alt=media&token=TOKEN
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;

        // pathSegments: ["v0", "b", "BUCKET", "o", "PATH"]
        if (pathSegments.length >= 5 &&
            pathSegments[1] == 'b' &&
            pathSegments[3] == 'o') {
          final bucket = pathSegments[2];
          // Rest of path segments joined by /
          final filePath = pathSegments.sublist(4).join('/');

          // Reconstruct with our local proxy
          // We keep query params as is
          final query = uri.hasQuery ? '?${uri.query}' : '';
          return 'http://136.248.64.90.nip.io/firebase/$bucket/$filePath$query';
        }
      } catch (e) {
        debugPrint('Error parsing Firebase URL for proxy: $e');
      }

      // Fallback: simple replace if structure is different
      return url
          .replaceFirst('https://firebasestorage.googleapis.com/v0/b/',
              'http://136.248.64.90.nip.io/firebase/')
          .replaceFirst('/o/', '/');
    } else if (url.contains('136.248.64.90.nip.io')) {
      // Force http for production domain until SSL is ready
      if (url.startsWith('https://')) {
        url = url.replaceFirst('https://', 'http://');
      }
      return url;
    } else if (url.contains('nip.io')) {
      return url;
    }

    if (!url.contains('cloudinary.com') || !url.contains('/upload/')) {
      return url;
    }

    String sanitized = url;

    // 1. Detect incorrectly mapped media type in URL
    bool isImageResource = sanitized.contains('/image/upload/');
    bool isVideoResource = sanitized.contains('/video/upload/');

    // 2. Remove incorrect extensions (especially .mp4 on images)
    if (mediaType == 'image' || isImageResource) {
      if (sanitized.toLowerCase().endsWith('.mp4')) {
        sanitized = sanitized.substring(0, sanitized.length - 4);
      }
      // Also remove video codec parameters from image URLs
      sanitized = sanitized.replaceAll(',vc_h264', '');
      sanitized = sanitized.replaceAll('vc_h264,', '');
      sanitized = sanitized.replaceAll('vc_h264/', '/');

      // Ensure it has optimization parameters for images
      if (!sanitized.contains('f_auto') && sanitized.contains('/upload/')) {
        sanitized =
            sanitized.replaceFirst('/upload/', '/upload/f_auto,q_auto/');
      }
    } else if (mediaType == 'video' || isVideoResource) {
      // 1. Identify the /upload/ part
      final uploadMatch = RegExp(r'(.+/upload/)(.*)').firstMatch(sanitized);
      if (uploadMatch != null) {
        final prefix = uploadMatch.group(1)!;
        final rest = uploadMatch.group(2)!;

        // 2. Separate transformations from the rest (version/publicId)
        // Cloudinary versions look like /v123456789/
        final versionMatch = RegExp(r'(.*)(v\d+/.+)').firstMatch(rest);

        String finalRest;
        if (versionMatch != null) {
          // url had a version
          finalRest = versionMatch.group(2)!;
        } else {
          // url might not have a version, just folders and name
          finalRest = rest;
          // If there are transformations before the name, they usually contain commas or equals
          if (finalRest.contains('/') &&
              (finalRest.split('/')[0].contains(',') ||
                  finalRest.split('/')[0].contains('='))) {
            finalRest = finalRest.substring(finalRest.indexOf('/') + 1);
          }
        }

        // 3. Clean query parameters and extensions from finalRest
        if (finalRest.contains('?')) {
          finalRest = finalRest.split('?')[0];
        }

        bool hadExtension = true;
        while (hadExtension) {
          hadExtension = false;
          final lowercase = finalRest.toLowerCase();
          for (final ext in [
            '.mov',
            '.mp4',
            '.avi',
            '.wmv',
            '.flv',
            '.mkv',
            '.webm'
          ]) {
            if (lowercase.endsWith(ext)) {
              finalRest = finalRest.substring(0, finalRest.length - ext.length);
              hadExtension = true;
              break;
            }
          }
        }

        // 4. Construct dynamic effects
        // Force H.264 and MP4 for universal browser compatibility (avoids AV1/WebM issues on web)
        List<String> transformations = ['vc_h264:main', 'q_auto:eco'];

        if (filterId != null) {
          switch (filterId) {
            case 'grayscale':
              transformations.add('e_grayscale');
              break;
            case 'sepia':
              transformations.add('e_sepia');
              break;
            case 'vintage':
              transformations.add('e_art:incognito');
              break;
            case 'warm':
              transformations.add('e_improve,e_warm');
              break;
            case 'cool':
              transformations.add('e_improve,e_cool');
              break;
          }
        }

        if (startOffset != null || endOffset != null) {
          String trim = '';
          if (startOffset != null) trim += 'so_$startOffset';
          if (endOffset != null) {
            if (trim.isNotEmpty) trim += ',';
            trim += 'eo_$endOffset';
          }
          transformations.add(trim);
        }

        final trStr = transformations.join(',');

        // 5. Reconstruct with new transformations
        // We ensure .mp4 is added to the publicId to bypass f_auto default behavior
        sanitized = '${prefix}$trStr/$finalRest.mp4';
      }
    }

    if (sanitized != url) {
      debugPrint('CloudinarySanitizer: $url -> $sanitized');
    }
    return sanitized;
  }
}
