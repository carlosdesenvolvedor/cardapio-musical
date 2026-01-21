class CloudinarySanitizer {
  static String sanitize(String url, {required String mediaType}) {
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
      // Ensure video optimization
      if (!sanitized.contains('vc_h264') && sanitized.contains('/upload/')) {
        sanitized = sanitized.replaceFirst(
            '/upload/', '/upload/f_auto,q_auto,vc_h264/');
      }
      // Ensure it ends with .mp4 for compatibility
      if (!sanitized.toLowerCase().endsWith('.mp4')) {
        sanitized = '$sanitized.mp4';
      }
    }

    return sanitized;
  }
}
