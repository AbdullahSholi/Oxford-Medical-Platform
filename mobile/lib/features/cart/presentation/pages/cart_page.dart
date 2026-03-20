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
      appBar: AppBar(title: Text(context.l10n.cartTitle)),
      body: BlocBuilder<CartBloc, CartState>(
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
                        onRemove: () {
                          context.read<CartBloc>().add(
                                CartItemRemoved(cart.items[index].productId),
                              );
                        },
                      );
                    },
                  ),
                ),
                // Order summary
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Coupon row
                        if (cart.couponCode == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _CouponInput(
                              onApply: (code) => context
                                  .read<CartBloc>()
                                  .add(CartCouponApplied(code)),
                            ),
                          ),
                        _SummaryRow(label: context.l10n.cartSubtotal, value: Formatters.price(cart.subtotal)),
                        if (cart.discount > 0)
                          _SummaryRow(
                            label: 'Discount',
                            value: '-${Formatters.price(cart.discount)}',
                            valueColor: AppColors.success,
                          ),
                        const Divider(height: AppSpacing.lg),
                        _SummaryRow(
                          label: context.l10n.cartTotal,
                          value: Formatters.price(cart.total),
                          isBold: true,
                        ),
                        AppSpacing.verticalGapLg,
                        AppButton(
                          label: context.l10n.cartCheckout,
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
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: _controller,
            hint: context.l10n.checkoutCoupon,
            maxLines: 1,
          ),
        ),
        AppSpacing.horizontalGapSm,
        AppButton(
          label: 'Apply',
          variant: AppButtonVariant.secondary,
          width: 80,
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onApply(_controller.text.trim());
            }
          },
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w400, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, fontSize: isBold ? 16 : 14, color: valueColor)),
        ],
      ),
    );
  }
}
