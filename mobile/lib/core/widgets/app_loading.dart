import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          AppSpacing.verticalGapSm,
          Container(height: 14, width: double.infinity, color: Colors.white),
          AppSpacing.verticalGapXs,
          Container(height: 14, width: 100, color: Colors.white),
          AppSpacing.verticalGapSm,
          Container(height: 18, width: 80, color: Colors.white),
        ],
      ),
    );
  }
}

class ProductGridShimmer extends StatelessWidget {
  final int itemCount;

  const ProductGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppSpacing.pagePadding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ProductCardShimmer(),
    );
  }
}

class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: AppSpacing.listItemPadding,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            AppSpacing.horizontalGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, color: Colors.white),
                  AppSpacing.verticalGapSm,
                  Container(height: 12, width: 150, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
