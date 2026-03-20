import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../domain/entities/banner.dart';

class PromoSlider extends StatefulWidget {
  final List<PromoBanner> banners;

  const PromoSlider({super.key, required this.banners});

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: AppCachedImage(
                    imageUrl: banner.imageUrl,
                    width: double.infinity,
                    height: 160,
                  ),
                ),
              );
            },
          ),
        ),
        AppSpacing.verticalGapSm,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
