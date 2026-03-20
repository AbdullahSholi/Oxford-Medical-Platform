import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

// Conditional import for web platform view
import 'cached_image_web.dart' if (dart.library.io) 'cached_image_native.dart'
    as platform;

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// On web, rewrite R2 public URLs to go through the nginx media proxy
  /// so that CORS headers are added. On mobile, use the original URL.
  String get _resolvedUrl {
    if (kIsWeb && imageUrl.startsWith(AppConstants.r2PublicUrl)) {
      return imageUrl.replaceFirst(
        AppConstants.r2PublicUrl,
        AppConstants.mediaBaseUrl,
      );
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    final url = _resolvedUrl;

    // On web, use platform-specific HTML img element to avoid CanvasKit CORS
    if (kIsWeb) {
      final image = platform.buildWebImage(
        url: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: _buildPlaceholder(),
      );

      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: image);
      }
      return image;
    }

    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
      memCacheWidth: (width != null && width!.isFinite) ? width!.toInt() : null,
      memCacheHeight: (height != null && height!.isFinite) ? height!.toInt() : null,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: AppColors.shimmerBase,
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.textHint),
        ),
      ),
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildPlaceholder() {
    final widget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.08),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.medical_services_outlined,
          color: AppColors.primary.withOpacity(0.3),
          size: (height ?? 48) * 0.35,
        ),
      ),
    );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: widget);
    }
    return widget;
  }
}
