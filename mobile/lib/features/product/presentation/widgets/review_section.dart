import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/rating_stars.dart';

class ReviewSection extends StatelessWidget {
  final double averageRating;
  final int reviewCount;

  const ReviewSection({
    super.key,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.horizontalGapLg,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingStars(rating: averageRating),
                AppSpacing.verticalGapXs,
                Text(
                  '$reviewCount reviews',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
