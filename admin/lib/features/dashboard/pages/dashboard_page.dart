import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  List<dynamic>? _revenueReport;
  List<dynamic>? _topProducts;
  Map<String, dynamic>? _doctorStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) return;
      final api = context.read<AuthCubit>().apiClient;

      // Load all data in parallel
      final results = await Future.wait([
        api.get('/admin/dashboard/stats'),
        api.get('/admin/reports/revenue').catchError((_) => <String, dynamic>{}),
        api.get('/admin/reports/products').catchError((_) => <String, dynamic>{}),
        api.get('/admin/reports/doctors').catchError((_) => <String, dynamic>{}),
      ]);

      setState(() {
        _stats = results[0]['data'] as Map<String, dynamic>?;
        _revenueReport = results[1]['data'] as List<dynamic>?;
        _topProducts = results[2]['data'] as List<dynamic>?;
        _doctorStats = results[3]['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: cs.error)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _loadAll, child: const Text('Retry')),
                  ],
                ))
              : ListView(
                  children: [
                    // Header
                    Row(
                      children: [
                        Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats cards
                    if (_stats != null) ...[
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _StatCard(title: 'Total Orders', value: '${_stats!['totalOrders'] ?? 0}', icon: Icons.shopping_bag_rounded, color: cs.primary, onTap: () => context.go('/orders')),
                          _StatCard(title: 'Total Revenue', value: 'EGP ${(double.tryParse((_stats!['totalRevenue'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}', icon: Icons.payments_rounded, color: const Color(0xFF10B981)),
                          _StatCard(title: 'Active Doctors', value: '${_stats!['activeDoctors'] ?? _stats!['totalDoctors'] ?? 0}', icon: Icons.people_rounded, color: const Color(0xFF8B5CF6), onTap: () => context.go('/doctors')),
                          _StatCard(title: 'Products', value: '${_stats!['totalProducts'] ?? 0}', icon: Icons.inventory_2_rounded, color: const Color(0xFFF59E0B), onTap: () => context.go('/products')),
                          _StatCard(title: 'Pending Orders', value: '${_stats!['pendingOrders'] ?? 0}', icon: Icons.hourglass_top_rounded, color: const Color(0xFFEF4444), onTap: () => context.go('/orders')),
                          _StatCard(title: 'Categories', value: '${_stats!['totalCategories'] ?? 0}', icon: Icons.category_rounded, color: const Color(0xFF3B82F6), onTap: () => context.go('/categories')),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Charts row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Revenue by Status chart
                        Expanded(
                          child: _ChartCard(
                            title: 'Orders by Status',
                            icon: Icons.pie_chart_rounded,
                            height: 280,
                            child: _revenueReport != null && _revenueReport!.isNotEmpty
                                ? _OrderStatusChart(data: _revenueReport!)
                                : const Center(child: Text('No data available')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Doctor Stats chart
                        Expanded(
                          child: _ChartCard(
                            title: 'Doctors by Status',
                            icon: Icons.people_rounded,
                            height: 280,
                            child: _doctorStats != null && _doctorStats!['byStatus'] != null
                                ? _DoctorStatusChart(data: _doctorStats!['byStatus'] as List)
                                : const Center(child: Text('No data available')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Products + Recent Orders row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Products
                        Expanded(
                          child: _ChartCard(
                            title: 'Top Products by Sales',
                            icon: Icons.trending_up_rounded,
                            height: 320,
                            child: _topProducts != null && _topProducts!.isNotEmpty
                                ? _TopProductsChart(data: _topProducts!)
                                : const Center(child: Text('No data available')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Recent Orders
                        Expanded(
                          child: _ChartCard(
                            title: 'Recent Orders',
                            icon: Icons.receipt_long_rounded,
                            height: 320,
                            child: _stats?['recentOrders'] != null
                                ? ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: (_stats!['recentOrders'] as List).length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final order = (_stats!['recentOrders'] as List)[i] as Map<String, dynamic>;
                                      return ListTile(
                                        dense: true,
                                        leading: _StatusChip(status: order['status'] as String? ?? 'pending'),
                                        title: Text('#${(order['id'] as String? ?? '').substring(0, 8).toUpperCase()}',
                                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                        subtitle: Text('${order['doctor']?['fullName'] ?? 'Unknown'}',
                                            style: const TextStyle(fontSize: 12)),
                                        trailing: Text(
                                          'EGP ${(double.tryParse((order['total'] ?? 0).toString()) ?? 0).toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        onTap: () => context.push('/orders/${order['id']}'),
                                      );
                                    },
                                  )
                                : const Center(child: Text('No recent orders')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

// ── Chart Widgets ──────────────────────────────────────

class _OrderStatusChart extends StatelessWidget {
  final List<dynamic> data;
  const _OrderStatusChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final legends = <_LegendItem>[];
    final total = data.fold<int>(0, (sum, d) => sum + ((d as Map)['_count']?['id'] ?? 0) as int);

    for (final item in data) {
      final m = item as Map<String, dynamic>;
      final status = m['status'] as String? ?? 'unknown';
      final count = (m['_count']?['id'] ?? 0) as int;
      final pct = total > 0 ? (count / total * 100) : 0.0;
      final color = _statusColor(status);

      sections.add(PieChartSectionData(
        value: count.toDouble(),
        color: color,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        radius: 50,
      ));
      legends.add(_LegendItem(color: color, label: '$status ($count)'));
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: legends.map((l) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(l.label, style: const TextStyle(fontSize: 11)),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFFF59E0B),
      'confirmed' => const Color(0xFF3B82F6),
      'processing' => const Color(0xFF8B5CF6),
      'shipped' => const Color(0xFF6366F1),
      'delivered' => const Color(0xFF10B981),
      'cancelled' => const Color(0xFFEF4444),
      _ => Colors.grey,
    };
  }
}

class _DoctorStatusChart extends StatelessWidget {
  final List<dynamic> data;
  const _DoctorStatusChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final legends = <_LegendItem>[];
    final total = data.fold<int>(0, (sum, d) => sum + ((d as Map)['_count']?['id'] ?? 0) as int);

    for (final item in data) {
      final m = item as Map<String, dynamic>;
      final status = m['status'] as String? ?? 'unknown';
      final count = (m['_count']?['id'] ?? 0) as int;
      final pct = total > 0 ? (count / total * 100) : 0.0;
      final color = _doctorStatusColor(status);

      sections.add(PieChartSectionData(
        value: count.toDouble(),
        color: color,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        radius: 50,
      ));
      legends.add(_LegendItem(color: color, label: '$status ($count)'));
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: legends.map((l) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(l.label, style: const TextStyle(fontSize: 11)),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Color _doctorStatusColor(String status) {
    return switch (status) {
      'approved' => const Color(0xFF10B981),
      'pending' => const Color(0xFFF59E0B),
      'rejected' => const Color(0xFFEF4444),
      'suspended' => const Color(0xFF6B7280),
      _ => Colors.grey,
    };
  }
}

class _TopProductsChart extends StatelessWidget {
  final List<dynamic> data;
  const _TopProductsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = data.take(8).toList();
    final maxSold = items.fold<int>(0, (max, d) {
      final sold = (d as Map<String, dynamic>)['totalSold'] as int? ?? 0;
      return sold > max ? sold : max;
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i] as Map<String, dynamic>;
        final name = p['name'] ?? 'Unknown';
        final sold = p['totalSold'] as int? ?? 0;
        final price = double.tryParse((p['price'] ?? 0).toString()) ?? 0;
        final fraction = maxSold > 0 ? sold / maxSold : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 24, child: Text('${i + 1}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$sold sold', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('EGP ${price.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                    if (onTap != null)
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double height;
  final Widget child;

  const _ChartCard({required this.title, required this.icon, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 24),
            SizedBox(height: height, child: child),
          ],
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

class _LegendItem {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
}
