import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/product.dart';

class MedicalDetailsTab extends StatelessWidget {
  final Product product;

  const MedicalDetailsTab({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final details = <MapEntry<String, String?>> [
      MapEntry('Manufacturer', product.manufacturer),
      MapEntry('Active Ingredient', product.activeIngredient),
      MapEntry('Dosage Form', product.dosageForm),
      MapEntry('Strength', product.strength),
      MapEntry('Pack Size', product.packSize),
      MapEntry('Requires Prescription', product.requiresPrescription ? 'Yes' : 'No'),
    ];

    final filtered = details.where((e) => e.value != null && e.value!.isNotEmpty).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Column(
          children: List.generate(filtered.length, (index) {
            final entry = filtered[index];
            final isLast = index == filtered.length - 1;
            final isPrescription = entry.key == 'Requires Prescription';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          _iconForKey(entry.key),
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isPrescription)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: entry.value == 'Yes' ? AppColors.warningLight : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                ),
                                child: Text(
                                  entry.value!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: entry.value == 'Yes' ? AppColors.warning : AppColors.success,
                                  ),
                                ),
                              )
                            else
                              Text(
                                entry.value!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 50, color: AppColors.divider),
              ],
            );
          }),
        ),
      ),
    );
  }

  IconData _iconForKey(String key) => switch (key) {
    'Manufacturer' => Icons.factory_outlined,
    'Active Ingredient' => Icons.science_outlined,
    'Dosage Form' => Icons.medication_outlined,
    'Strength' => Icons.speed_outlined,
    'Pack Size' => Icons.inventory_2_outlined,
    'Requires Prescription' => Icons.receipt_long_rounded,
    _ => Icons.info_outline_rounded,
  };
}
