import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 999,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onTap: quantity > min ? () => onChanged(quantity - 1) : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onTap: quantity < max ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.textPrimary : AppColors.textHint,
        ),
      ),
    );
  }
}
