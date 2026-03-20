import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<dynamic> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/admin/products');
      setState(() { _products = (res['data'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await context.read<AuthCubit>().apiClient.delete('/admin/products/$id');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
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
              Text('Products', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.push('/products/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('SKU')),
                              DataColumn(label: Text('Price'), numeric: true),
                              DataColumn(label: Text('Stock'), numeric: true),
                              DataColumn(label: Text('Sold'), numeric: true),
                              DataColumn(label: Text('Active')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _products.map((p) {
                              final prod = p as Map<String, dynamic>;
                              return DataRow(cells: [
                                DataCell(SizedBox(width: 200, child: Text(prod['name'] ?? '', overflow: TextOverflow.ellipsis))),
                                DataCell(Text(prod['sku'] ?? '')),
                                DataCell(Text('EGP ${(double.tryParse((prod['price'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}')),
                                DataCell(Text('${prod['stock'] ?? 0}')),
                                DataCell(Text('${prod['totalSold'] ?? 0}')),
                                DataCell(Icon(
                                  prod['isActive'] == true ? Icons.check_circle : Icons.cancel,
                                  color: prod['isActive'] == true ? const Color(0xFF10B981) : cs.error,
                                  size: 20,
                                )),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: 'Edit',
                                      onPressed: () => context.push('/products/${prod['id']}/edit'),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                                      tooltip: 'Delete',
                                      onPressed: () => _delete(prod['id'] as String, prod['name'] as String? ?? ''),
                                    ),
                                  ],
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
}
