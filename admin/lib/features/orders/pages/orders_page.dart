import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../auth/cubit/auth_cubit.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _statusFilter;
  int _page = 1;
  int _totalPages = 1;

  ApiClient get _api => context.read<AuthCubit>().apiClient;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final query = <String, dynamic>{'page': _page, 'limit': 20};
      if (_statusFilter != null) query['status'] = _statusFilter;
      final res = await _api.get('/admin/orders', query: query);
      setState(() {
        _orders = (res['data'] as List?) ?? [];
        final meta = res['meta'] as Map<String, dynamic>?;
        _totalPages = meta?['totalPages'] ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const statuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orders', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Status filter chips
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _statusFilter == null,
                onSelected: (_) { _statusFilter = null; _page = 1; _load(); },
              ),
              ...statuses.map((s) => FilterChip(
                label: Text(s[0].toUpperCase() + s.substring(1)),
                selected: _statusFilter == s,
                onSelected: (_) { _statusFilter = s; _page = 1; _load(); },
              )),
            ],
          ),
          const SizedBox(height: 16),
          // Orders table
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('No orders found'))
                    : Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
                            columns: const [
                              DataColumn(label: Text('Order ID')),
                              DataColumn(label: Text('Doctor')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Items')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Date')),
                            ],
                            rows: _orders.map((o) {
                              final order = o as Map<String, dynamic>;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text('#${(order['id'] as String? ?? '').substring(0, 8).toUpperCase()}',
                                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                                    onTap: () => context.push('/orders/${order['id']}'),
                                  ),
                                  DataCell(Text(order['doctor']?['fullName'] ?? 'N/A')),
                                  DataCell(_buildStatusChip(order['status'] as String? ?? 'pending')),
                                  DataCell(Text('${order['itemCount'] ?? order['items']?.length ?? 0}')),
                                  DataCell(Text('EGP ${(double.tryParse((order['total'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}')),
                                  DataCell(Text(_formatDate(order['createdAt'] as String?))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1 ? () { _page--; _load(); } : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_page of $_totalPages'),
                  IconButton(
                    onPressed: _page < _totalPages ? () { _page++; _load(); } : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final (color, label) = switch (status) {
      'pending' => (const Color(0xFFF59E0B), 'Pending'),
      'confirmed' => (const Color(0xFF3B82F6), 'Confirmed'),
      'processing' => (const Color(0xFF8B5CF6), 'Processing'),
      'shipped' => (const Color(0xFF6366F1), 'Shipped'),
      'delivered' => (const Color(0xFF10B981), 'Delivered'),
      'cancelled' => (const Color(0xFFEF4444), 'Cancelled'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'N/A';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
