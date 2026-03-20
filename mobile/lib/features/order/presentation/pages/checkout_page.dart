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
          // Auto-select default address
          for (final addr in _addresses) {
            if (addr['isDefault'] == true) {
              _selectedAddressId = addr['id'] as String;
              _selectedAddressLabel = '${addr['label']} - ${addr['streetAddress'] ?? addr['street'] ?? ''}, ${addr['city'] ?? ''}';
              break;
            }
          }
          // If no default, select first
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
          // Refresh cart (it's been cleared on backend)
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
      appBar: AppBar(title: Text(context.l10n.checkoutTitle)),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoadedState) return const SizedBox.shrink();
          final cart = state.cart;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
                Text(context.l10n.checkoutAddress, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.verticalGapMd,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border.all(color: _selectedAddressId != null ? AppColors.primary : AppColors.divider),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      AppSpacing.horizontalGapMd,
                      Expanded(
                        child: _loadingAddresses
                            ? const Text('Loading addresses...')
                            : Text(_selectedAddressLabel ?? 'No address found'),
                      ),
                      if (_addresses.length > 1)
                        TextButton(onPressed: _showAddressPicker, child: const Text('Change')),
                    ],
                  ),
                ),
                AppSpacing.verticalGapXl,

                // Payment
                Text(context.l10n.checkoutPayment, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.verticalGapMd,
                RadioListTile<String>(
                  title: const Text('Cash on Delivery'),
                  value: 'cash_on_delivery',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  title: const Text('Credit Card'),
                  value: 'credit_card',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  contentPadding: EdgeInsets.zero,
                ),
                AppSpacing.verticalGapXl,

                // Coupon
                Text('Discount Code', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.verticalGapMd,
                if (_couponApplied)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_rounded, color: AppColors.success, size: 20),
                        AppSpacing.horizontalGapSm,
                        Expanded(child: Text(_discountCode!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _removeCoupon,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: _couponController, hint: 'Enter coupon code', maxLines: 1)),
                      AppSpacing.horizontalGapSm,
                      AppButton(label: 'Apply', variant: AppButtonVariant.secondary, width: 80, onPressed: _applyCoupon),
                    ],
                  ),
                AppSpacing.verticalGapXl,

                // Order Summary
                Text('Order Summary', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.verticalGapMd,
                ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text('${item.productName} x${item.quantity}', style: const TextStyle(fontSize: 13))),
                    Text(Formatters.price(item.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                )),
                const Divider(),
                _SummaryRow(label: 'Subtotal', value: Formatters.price(cart.subtotal)),
                if (cart.discount > 0) _SummaryRow(label: 'Discount', value: '-${Formatters.price(cart.discount)}'),
                _SummaryRow(
                  label: 'Delivery',
                  value: cart.subtotal >= 500 ? 'Free' : Formatters.price(25),
                ),
                const Divider(),
                _SummaryRow(
                  label: 'Total',
                  value: Formatters.price(cart.subtotal < 500 ? cart.total + 25 : cart.total),
                  isBold: true,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: _placingOrder ? 'Placing Order...' : context.l10n.checkoutPlaceOrder,
            onPressed: _placingOrder ? null : _placeOrder,
          ),
        ),
      ),
    );
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: _addresses.map((addr) {
          final id = addr['id'] as String;
          final label = '${addr['label']} - ${addr['streetAddress'] ?? addr['street'] ?? ''}, ${addr['city'] ?? ''}';
          return ListTile(
            leading: Icon(Icons.location_on, color: id == _selectedAddressId ? AppColors.primary : AppColors.textSecondary),
            title: Text(label),
            trailing: id == _selectedAddressId ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () {
              setState(() { _selectedAddressId = id; _selectedAddressLabel = label; });
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _SummaryRow({required this.label, required this.value, this.isBold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : null)),
      Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
    ]),
  );
}
