import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';

class BannersPage extends StatefulWidget {
  const BannersPage({super.key});
  @override
  State<BannersPage> createState() => _BannersPageState();
}

class _BannersPageState extends State<BannersPage> {
  List<dynamic> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/admin/banners');
      setState(() { _banners = (res['data'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String id) async {
    try {
      await context.read<AuthCubit>().apiClient.patch('/admin/banners/$id/toggle');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure?'),
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
      await context.read<AuthCubit>().apiClient.delete('/admin/banners/$id');
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
              Text('Banners', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _banners.isEmpty
                    ? const Center(child: Text('No banners found'))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _banners.length,
                        itemBuilder: (context, i) {
                          final banner = _banners[i] as Map<String, dynamic>;
                          final isActive = banner['isActive'] ?? false;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (banner['imageUrl'] != null)
                                  Image.network(banner['imageUrl'] as String, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: cs.primaryContainer,
                                        child: Icon(Icons.image, size: 48, color: cs.primary),
                                      ))
                                else
                                  Container(
                                    color: cs.primaryContainer,
                                    child: Center(child: Text(banner['title'] ?? 'Banner',
                                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 18))),
                                  ),
                                // Overlay controls
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: Container(
                                    color: Colors.black54,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(banner['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                        IconButton(
                                          icon: Icon(isActive ? Icons.visibility : Icons.visibility_off, color: Colors.white, size: 20),
                                          tooltip: isActive ? 'Deactivate' : 'Activate',
                                          onPressed: () => _toggle(banner['id'] as String),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                          tooltip: 'Delete',
                                          onPressed: () => _delete(banner['id'] as String),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Active badge
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(isActive ? 'Active' : 'Inactive',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
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
