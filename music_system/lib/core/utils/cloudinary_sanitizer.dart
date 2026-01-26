class CloudinarySanitizer {
  static String sanitize(
    String url, {
    required String mediaType,
    String? filterId,
    double? startOffset,
    double? endOffset,
  }) {
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

    return sanitized;
  }
}
