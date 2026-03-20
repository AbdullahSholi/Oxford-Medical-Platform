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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        children: details
            .where((e) => e.value != null && e.value!.isNotEmpty)
            .map((entry) => _DetailRow(label: entry.key, value: entry.value!))
            .toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
