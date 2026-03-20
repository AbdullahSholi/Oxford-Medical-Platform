import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onRated;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.activeColor = AppColors.warning,
    this.inactiveColor = AppColors.divider,
    this.onRated,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          color = activeColor;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          color = activeColor;
        } else {
          icon = Icons.star_border_rounded;
          color = inactiveColor;
        }

        return GestureDetector(
          onTap: onRated != null ? () => onRated!(starValue) : null,
          child: Icon(icon, size: size, color: color),
        );
      }),
    );
  }
}
