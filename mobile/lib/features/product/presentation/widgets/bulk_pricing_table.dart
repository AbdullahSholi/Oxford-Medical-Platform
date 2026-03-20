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
    return Table(
      border: TableBorder.all(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppColors.surfaceVariant),
          children: [
            _Cell(text: 'Quantity', isHeader: true),
            _Cell(text: 'Price per Unit', isHeader: true),
          ],
        ),
        ...pricing.map((tier) => TableRow(
              children: [
                _Cell(text: '${tier.minQuantity} - ${tier.maxQuantity}'),
                _Cell(text: Formatters.price(tier.pricePerUnit)),
              ],
            )),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _Cell({required this.text, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
      ),
    );
  }
}
