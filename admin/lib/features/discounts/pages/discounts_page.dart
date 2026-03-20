import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class DiscountsPage extends StatefulWidget {
  const DiscountsPage({super.key});
  @override
  State<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  List<dynamic> _discounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/admin/discounts');
      setState(() { _discounts = (res['data'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
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
              Text('Discounts', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.push('/discounts/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Discount'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _discounts.isEmpty
                    ? const Center(child: Text('No discounts found'))
                    : Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
                            columns: const [
                              DataColumn(label: Text('Code')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Value')),
                              DataColumn(label: Text('Usage')),
                              DataColumn(label: Text('Starts')),
                              DataColumn(label: Text('Ends')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: _discounts.map((d) {
                              final disc = d as Map<String, dynamic>;
                              final now = DateTime.now();
                              final endsAt = DateTime.tryParse(disc['endsAt']?.toString() ?? '');
                              final startsAt = DateTime.tryParse(disc['startsAt']?.toString() ?? '');
                              final isExpired = endsAt != null && endsAt.isBefore(now);
                              final isUpcoming = startsAt != null && startsAt.isAfter(now);

                              return DataRow(cells: [
                                DataCell(Text(disc['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
                                DataCell(Text(disc['type'] ?? '')),
                                DataCell(Text(disc['type'] == 'percentage' ? '${disc['value']}%' : 'EGP ${disc['value']}')),
                                DataCell(Text('${disc['usageCount'] ?? 0}/${disc['usageLimit'] ?? '∞'}')),
                                DataCell(Text(_formatDate(disc['startsAt']?.toString()))),
                                DataCell(Text(_formatDate(disc['endsAt']?.toString()))),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isExpired ? const Color(0xFFEF4444) : isUpcoming ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isExpired ? 'Expired' : isUpcoming ? 'Upcoming' : 'Active',
                                    style: TextStyle(
                                      color: isExpired ? const Color(0xFFEF4444) : isUpcoming ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
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
