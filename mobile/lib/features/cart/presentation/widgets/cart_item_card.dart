import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../domain/entities/cart.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          AppCachedImage(
            imageUrl: item.productImage,
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          AppSpacing.horizontalGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                AppSpacing.verticalGapSm,
                Text(
                  Formatters.price(item.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.verticalGapSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuantitySelector(
                      quantity: item.quantity,
                      onChanged: onQuantityChanged,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
