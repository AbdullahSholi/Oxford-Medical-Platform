import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/categories');
      setState(() { _categories = (res['data'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  Future<void> _delete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "$name"? Products in this category will become uncategorized.'),
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
      await context.read<AuthCubit>().apiClient.delete('/admin/categories/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted'), backgroundColor: Color(0xFF10B981)),
        );
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
              Text('Categories', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Text('${_categories.length}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => context.push('/categories/new'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text('No categories yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/categories/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create your first category'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final cat = _categories[i] as Map<String, dynamic>;
                          final name = cat['name'] ?? 'Unnamed';
                          final slug = cat['slug'] ?? '';
                          final productCount = cat['_count']?['products'] ?? cat['productCount'] ?? 0;
                          final children = (cat['children'] as List?)?.length ?? 0;
                          final iconUrl = cat['iconUrl'] as String?;

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/categories/${cat['id']}/edit'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: iconUrl != null && iconUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.network(iconUrl, fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Icon(Icons.category, color: cs.primary)),
                                                )
                                              : Icon(Icons.category, color: cs.primary),
                                        ),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'), dense: true, contentPadding: EdgeInsets.zero)),
                                            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Color(0xFFEF4444)), title: Text('Delete', style: TextStyle(color: Color(0xFFEF4444))), dense: true, contentPadding: EdgeInsets.zero)),
                                          ],
                                          onSelected: (action) {
                                            if (action == 'edit') context.push('/categories/${cat['id']}/edit');
                                            if (action == 'delete') _delete(cat['id'] as String, name);
                                          },
                                          icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(slug, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 14, color: cs.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text('$productCount products', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                        if (children > 0) ...[
                                          const SizedBox(width: 12),
                                          Icon(Icons.account_tree_outlined, size: 14, color: cs.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text('$children sub', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
