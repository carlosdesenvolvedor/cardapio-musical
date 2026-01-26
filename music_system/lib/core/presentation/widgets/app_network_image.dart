import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shimmer/shimmer.dart';
import 'package:music_system/core/utils/cloudinary_sanitizer.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool useShimmer;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.useShimmer = true,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl =
        CloudinarySanitizer.sanitize(imageUrl, mediaType: 'image');

    if (kIsWeb) {
      // No Web, o CachedNetworkImage causa problemas de CORS ao tentar buscar bytes.
      // O Image.network usa a tag <img> nativa que costuma ignorar CORS simples.
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          sanitizedUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder();
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: sanitizedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (!useShimmer) return const Center(child: CircularProgressIndicator());
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.black,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      child: const Icon(Icons.error, color: Colors.white24),
    );
  }

  /// Utility to get an ImageProvider that works on Web and Mobile
  static ImageProvider provider(String url) {
    final sanitizedUrl = CloudinarySanitizer.sanitize(url, mediaType: 'image');
    if (kIsWeb) {
      return NetworkImage(sanitizedUrl);
    }
    return CachedNetworkImageProvider(sanitizedUrl);
  }
}
