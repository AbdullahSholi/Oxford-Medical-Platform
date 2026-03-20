import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
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
