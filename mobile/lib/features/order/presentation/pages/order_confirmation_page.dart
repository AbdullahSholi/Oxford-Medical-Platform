import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class OrderConfirmationPage extends StatelessWidget {
  final String orderId;
  const OrderConfirmationPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Layered success icon with glow
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 36, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.verticalGapXl,
              const Text(
                'Order Placed!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              AppSpacing.verticalGapMd,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your order has been placed successfully.\nYou can track your order in real-time.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Track Order',
                icon: Icons.location_on_outlined,
                variant: AppButtonVariant.gradient,
                onPressed: () => context.go('/orders/$orderId/tracking'),
              ),
              AppSpacing.verticalGapMd,
              AppButton(
                label: 'View Order Details',
                variant: AppButtonVariant.secondary,
                icon: Icons.receipt_long_rounded,
                onPressed: () => context.go('/orders/$orderId'),
              ),
              AppSpacing.verticalGapMd,
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text('Continue Shopping'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
