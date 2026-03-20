import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../auth/cubit/auth_cubit.dart';

class OrderDetailPage extends StatefulWidget {
  final String id;
  const OrderDetailPage({super.key, required this.id});
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _updating = false;

  ApiClient get _api => context.read<AuthCubit>().apiClient;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/admin/orders/${widget.id}');
      setState(() { _order = res['data'] as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await _api.patch('/admin/orders/${widget.id}/status', data: {'status': newStatus});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated to $newStatus'), backgroundColor: const Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_order == null) return const Center(child: Text('Order not found'));

    final order = _order!;
    final items = (order['items'] as List?) ?? [];
    final status = order['status'] as String? ?? 'pending';
    const statusFlow = ['pending', 'confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered'];
    final currentIdx = statusFlow.indexOf(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(onPressed: () => context.go('/orders'), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text('Order #${widget.id.substring(0, 8).toUpperCase()}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (status != 'cancelled' && status != 'delivered' && !_updating) ...[
                // Next status button
                if (currentIdx >= 0 && currentIdx < statusFlow.length - 1)
                  FilledButton.icon(
                    onPressed: () => _updateStatus(statusFlow[currentIdx + 1]),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text('Mark ${statusFlow[currentIdx + 1][0].toUpperCase()}${statusFlow[currentIdx + 1].substring(1)}'),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _updateStatus('cancelled'),
                  icon: Icon(Icons.cancel_outlined, size: 18, color: cs.error),
                  label: Text('Cancel', style: TextStyle(color: cs.error)),
                ),
              ],
              if (_updating) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 24),
          // Info cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order info
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _InfoRow('Status', status.toUpperCase()),
                        _InfoRow('Doctor', order['doctor']?['fullName'] ?? 'N/A'),
                        _InfoRow('Email', order['doctor']?['email'] ?? 'N/A'),
                        _InfoRow('Subtotal', 'EGP ${(double.tryParse((order['subtotal'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}'),
                        _InfoRow('Delivery', 'EGP ${(double.tryParse((order['deliveryFee'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}'),
                        if (order['discountAmount'] != null && (double.tryParse(order['discountAmount'].toString()) ?? 0) > 0)
                          _InfoRow('Discount', '-EGP ${(double.tryParse((order['discountAmount']).toString()) ?? 0).toStringAsFixed(2)}'),
                        const Divider(),
                        _InfoRow('Total', 'EGP ${(double.tryParse((order['total'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}', bold: true),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Items
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items (${items.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        ...items.map((item) {
                          final i = item as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(child: Text(i['product']?['name'] ?? i['productName'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text('${i['quantity']} x EGP ${(double.tryParse((i['unitPrice'] ?? i['price'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}'),
                                const SizedBox(width: 16),
                                Text('EGP ${(double.tryParse((i['totalPrice'] ?? ((i['quantity'] ?? 1) * (double.tryParse((i['unitPrice'] ?? i['price'] ?? 0).toString()) ?? 0))).toString()) ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
