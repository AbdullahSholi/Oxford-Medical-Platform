import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/repositories/order_repository.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedAddressId;
  String? _selectedAddressLabel;
  String _paymentMethod = 'cash_on_delivery';
  String? _discountCode;
  bool _couponApplied = false;
  List<Map<String, dynamic>> _addresses = [];
  bool _loadingAddresses = true;
  bool _placingOrder = false;
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final apiClient = di.sl<ApiClient>();
      final response = await apiClient.get<List<dynamic>>(
        ApiEndpoints.doctorAddresses,
        parser: (data) => data is List ? data : (data as Map<String, dynamic>)['data'] as List? ?? [],
      );
      if (response.success && response.data != null) {
        setState(() {
          _addresses = response.data!.cast<Map<String, dynamic>>();
          _loadingAddresses = false;
          for (final addr in _addresses) {
            if (addr['isDefault'] == true) {
              _selectedAddressId = addr['id'] as String;
              _selectedAddressLabel = '${addr['label']} - ${addr['streetAddress'] ?? addr['street'] ?? ''}, ${addr['city'] ?? ''}';
              break;
            }
          }
          if (_selectedAddressId == null && _addresses.isNotEmpty) {
            final addr = _addresses.first;
            _selectedAddressId = addr['id'] as String;
            _selectedAddressLabel = '${addr['label']} - ${addr['streetAddress'] ?? addr['street'] ?? ''}, ${addr['city'] ?? ''}';
          }
        });
      } else {
        setState(() => _loadingAddresses = false);
      }
    } catch (e) {
      setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      context.showSnackBar('Please select a delivery address');
      return;
    }
    setState(() => _placingOrder = true);
    try {
      final repo = di.sl<OrderRepository>();
      final result = await repo.checkout(
        addressId: _selectedAddressId!,
        paymentMethod: _paymentMethod == 'cash_on_delivery' ? 'cod' : _paymentMethod,
        discountCode: _couponApplied ? _discountCode : null,
      );
      result.fold(
        (failure) {
          setState(() => _placingOrder = false);
          context.showSnackBar(failure.message);
        },
        (order) {
          context.read<CartBloc>().add(const CartLoaded());
          context.go('/orders/${order.id}/confirmation');
        },
      );
    } catch (e) {
      setState(() => _placingOrder = false);
      context.showSnackBar('Failed to place order: $e');
    }
  }

  void _applyCoupon() {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _discountCode = code;
      _couponApplied = true;
    });
    context.showSnackBar('Coupon "$code" will be applied at checkout');
  }

  void _removeCoupon() {
    setState(() {
      _discountCode = null;
      _couponApplied = false;
      _couponController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.checkoutTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoadedState) return const SizedBox.shrink();
          final cart = state.cart;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address section
                _SectionCard(
                  title: context.l10n.checkoutAddress,
                  icon: Icons.location_on_rounded,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedAddressId != null
                          ? AppColors.primarySurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: _selectedAddressId != null
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _loadingAddresses
                              ? const Text('Loading addresses...', style: TextStyle(color: AppColors.textSecondary))
                              : Text(
                                  _selectedAddressLabel ?? 'No address found',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                        ),
                        if (_addresses.length > 1)
                          TextButton(
                            onPressed: _showAddressPicker,
                            child: const Text('Change', style: TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.verticalGapLg,

                // Payment section
                _SectionCard(
                  title: context.l10n.checkoutPayment,
                  icon: Icons.payment_rounded,
                  child: Column(
                    children: [
                      _PaymentOption(
                        title: 'Cash on Delivery',
                        icon: Icons.money_rounded,
                        value: 'cash_on_delivery',
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                      const SizedBox(height: 8),
                      _PaymentOption(
                        title: 'Credit Card',
                        icon: Icons.credit_card_rounded,
                        value: 'credit_card',
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalGapLg,

                // Coupon section
                _SectionCard(
                  title: 'Discount Code',
                  icon: Icons.local_offer_rounded,
                  child: _couponApplied
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_discountCode!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success))),
                              GestureDetector(
                                onTap: _removeCoupon,
                                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        )
                      : Container(
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
                                  controller: _couponController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter coupon code',
                                    hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              TextButton(
                                onPressed: _applyCoupon,
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
                        ),
                ),
                AppSpacing.verticalGapLg,

                // Order Summary
                _SectionCard(
                  title: 'Order Summary',
                  icon: Icons.receipt_long_rounded,
                  child: Column(
                    children: [
                      ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} x${item.quantity}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                            Text(
                              Formatters.price(item.total),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                      _SummaryRow(label: 'Subtotal', value: Formatters.price(cart.subtotal)),
                      if (cart.discount > 0)
                        _SummaryRow(label: 'Discount', value: '-${Formatters.price(cart.discount)}', valueColor: AppColors.success),
                      _SummaryRow(
                        label: 'Delivery',
                        value: cart.subtotal >= 500 ? 'Free' : Formatters.price(25),
                        valueColor: cart.subtotal >= 500 ? AppColors.success : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                      _SummaryRow(
                        label: 'Total',
                        value: Formatters.price(cart.subtotal < 500 ? cart.total + 25 : cart.total),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
          child: AppButton(
            label: _placingOrder ? 'Placing Order...' : context.l10n.checkoutPlaceOrder,
            variant: AppButtonVariant.gradient,
            isLoading: _placingOrder,
            onPressed: _placingOrder ? null : _placeOrder,
          ),
        ),
      ),
    );
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Select Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._addresses.map((addr) {
              final id = addr['id'] as String;
              final label = '${addr['label']} - ${addr['streetAddress'] ?? addr['street'] ?? ''}, ${addr['city'] ?? ''}';
              final isSelected = id == _selectedAddressId;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primarySurface : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(Icons.location_on_rounded, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
                ),
                title: Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  setState(() { _selectedAddressId = id; _selectedAddressLabel = label; });
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.isBold = false, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
        fontSize: isBold ? 16 : 14,
        color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
      )),
      Text(value, style: TextStyle(
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        fontSize: isBold ? 18 : 14,
        color: valueColor ?? (isBold ? AppColors.primary : AppColors.textPrimary),
      )),
    ]),
  );
}
