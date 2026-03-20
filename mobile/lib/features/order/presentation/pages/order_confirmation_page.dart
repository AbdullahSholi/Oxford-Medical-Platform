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
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
              ),
              AppSpacing.verticalGapXl,
              Text(
                'Order Placed!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              AppSpacing.verticalGapMd,
              const Text(
                'Your order has been placed successfully.\nYou can track your order in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const Spacer(),
              AppButton(
                label: 'Track Order',
                icon: Icons.location_on_outlined,
                onPressed: () => context.go('/orders/$orderId/tracking'),
              ),
              AppSpacing.verticalGapMd,
              AppButton(
                label: 'View Order Details',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go('/orders/$orderId'),
              ),
              AppSpacing.verticalGapMd,
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
