import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/cart_bloc.dart';
import '../widgets/cart_item_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.cartTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartErrorState) {
            context.showErrorDialog(
              title: 'Cart Error',
              message: state.message,
            );
          }
          if (state is CartLoadedState) {
            if (state.cart.couponCode != null) {
              context.showSuccessSnackBar('Coupon "${state.cart.couponCode}" applied successfully!');
            }
          }
        },
        builder: (context, state) {
          if (state is CartInitial) {
            context.read<CartBloc>().add(const CartLoaded());
            return const AppLoading();
          }
          if (state is CartLoadingState) return const AppLoading();
          if (state is CartErrorState) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<CartBloc>().add(const CartLoaded()),
            );
          }
          if (state is CartLoadedState) {
            final cart = state.cart;
            if (cart.isEmpty) {
              return AppEmptyState(
                title: context.l10n.cartEmpty,
                icon: Icons.shopping_cart_outlined,
                actionLabel: 'Browse Products',
                onAction: () => context.go('/home'),
              );
            }
            return Column(
              children: [
                // Items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => AppSpacing.verticalGapMd,
                    itemBuilder: (context, index) {
                      return CartItemCard(
                        item: cart.items[index],
                        onQuantityChanged: (qty) {
                          context.read<CartBloc>().add(CartItemQuantityUpdated(
                                itemId: cart.items[index].productId,
                                quantity: qty,
                              ));
                        },
                        onRemove: () async {
                          final confirmed = await context.showConfirmDialog(
                            title: 'Remove Item',
                            message: 'Are you sure you want to remove "${cart.items[index].productName}" from your cart?',
                            confirmLabel: 'Remove',
                            cancelLabel: 'Keep',
                          );
                          if (confirmed == true && context.mounted) {
                            context.read<CartBloc>().add(
                                  CartItemRemoved(cart.items[index].productId),
                                );
                          }
                        },
                      );
                    },
                  ),
                ),
                // Modern order summary
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Coupon row
                        if (cart.couponCode == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: _CouponInput(
                              onApply: (code) => context
                                  .read<CartBloc>()
                                  .add(CartCouponApplied(code)),
                            ),
                          ),
                        _SummaryRow(
                          label: context.l10n.cartSubtotal,
                          value: Formatters.price(cart.subtotal),
                        ),
                        if (cart.discount > 0)
                          _SummaryRow(
                            label: 'Discount',
                            value: '-${Formatters.price(cart.discount)}',
                            valueColor: AppColors.success,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            color: AppColors.divider,
                            height: 1,
                          ),
                        ),
                        _SummaryRow(
                          label: context.l10n.cartTotal,
                          value: Formatters.price(cart.total),
                          isBold: true,
                        ),
                        AppSpacing.verticalGapLg,
                        AppButton(
                          label: context.l10n.cartCheckout,
                          variant: AppButtonVariant.gradient,
                          onPressed: () => context.push('/checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CouponInput extends StatefulWidget {
  final ValueChanged<String> onApply;
  const _CouponInput({required this.onApply});

  @override
  State<_CouponInput> createState() => _CouponInputState();
}

class _CouponInputState extends State<_CouponInput> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: context.l10n.checkoutCoupon,
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                widget.onApply(_controller.text.trim());
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              fontSize: isBold ? 16 : 14,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 18 : 14,
              color: valueColor ?? (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
