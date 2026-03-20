import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) return;
      final apiClient = context.read<AuthCubit>().apiClient;
      final res = await apiClient.get('/admin/dashboard/stats');
      setState(() { _stats = res['data'] as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: cs.error)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadStats, child: const Text('Retry')),
              ],
            ))
          else if (_stats != null) ...[
            // Stats cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Orders',
                  value: '${_stats!['totalOrders'] ?? 0}',
                  icon: Icons.shopping_bag_rounded,
                  color: cs.primary,
                ),
                _StatCard(
                  title: 'Total Revenue',
                  value: 'EGP ${(double.tryParse((_stats!['totalRevenue'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}',
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981),
                ),
                _StatCard(
                  title: 'Active Doctors',
                  value: '${_stats!['activeDoctors'] ?? 0}',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                _StatCard(
                  title: 'Products',
                  value: '${_stats!['totalProducts'] ?? 0}',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                _StatCard(
                  title: 'Pending Orders',
                  value: '${_stats!['pendingOrders'] ?? 0}',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFEF4444),
                ),
                _StatCard(
                  title: 'Categories',
                  value: '${_stats!['totalCategories'] ?? 0}',
                  icon: Icons.category_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Recent orders section
            Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_stats!['recentOrders'] != null)
              Expanded(
                child: Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: (_stats!['recentOrders'] as List).length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final order = (_stats!['recentOrders'] as List)[i] as Map<String, dynamic>;
                      return ListTile(
                        leading: _StatusChip(status: order['status'] as String? ?? 'pending'),
                        title: Text('#${(order['id'] as String? ?? '').substring(0, 8).toUpperCase()}'),
                        subtitle: Text('${order['doctor']?['fullName'] ?? 'Unknown'} • ${order['itemCount'] ?? 0} items'),
                        trailing: Text('EGP ${(double.tryParse((order['total'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),
              )
            else
              const Expanded(child: Center(child: Text('No recent orders'))),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
