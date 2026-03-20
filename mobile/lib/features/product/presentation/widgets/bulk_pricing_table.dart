import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/product.dart';

class BulkPricingTable extends StatelessWidget {
  final List<BulkPricing> pricing;

  const BulkPricingTable({super.key, required this.pricing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Price per Unit',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          ...List.generate(pricing.length, (index) {
            final tier = pricing[index];
            final isLast = index == pricing.length - 1;
            final isBest = index == pricing.length - 1 && pricing.length > 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${tier.minQuantity} - ${tier.maxQuantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isBest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                ),
                                child: const Text(
                                  'Best',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        Formatters.price(tier.pricePerUnit),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
                          color: isBest ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, color: AppColors.divider),
              ],
            );
          }),
        ],
      ),
    );
  }
}
