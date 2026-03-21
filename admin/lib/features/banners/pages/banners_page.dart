import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class BannersPage extends StatefulWidget {
  const BannersPage({super.key});
  @override
  State<BannersPage> createState() => _BannersPageState();
}

class _BannersPageState extends State<BannersPage> {
  List<dynamic> _banners = [];
  bool _loading = true;
  String _filterPosition = 'all';

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
        content: const Text('This action cannot be undone. Are you sure?'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner deleted'), backgroundColor: Color(0xFF10B981)),
        );
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  List<dynamic> get _filtered {
    if (_filterPosition == 'all') return _banners;
    return _banners.where((b) => (b as Map<String, dynamic>)['position'] == _filterPosition).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Banners', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Text('${_banners.length}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const Spacer(),
              // Position filter
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'home_slider', label: Text('Home')),
                  ButtonSegment(value: 'category_banner', label: Text('Category')),
                  ButtonSegment(value: 'flash_sale', label: Text('Flash Sale')),
                ],
                selected: {_filterPosition},
                onSelectionChanged: (v) => setState(() => _filterPosition = v.first),
                style: ButtonStyle(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(width: 12),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => context.push('/banners/new'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Banner'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text('No banners found', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/banners/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create your first banner'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final banner = _filtered[i] as Map<String, dynamic>;
                          return _BannerCard(
                            banner: banner,
                            onEdit: () => context.push('/banners/${banner['id']}/edit'),
                            onToggle: () => _toggle(banner['id'] as String),
                            onDelete: () => _delete(banner['id'] as String),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerCard({required this.banner, required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = banner['isActive'] ?? false;
    final position = banner['position'] ?? 'home_slider';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onEdit,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (banner['imageUrl'] != null)
              Image.network(
                banner['imageUrl'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  child: Icon(Icons.broken_image_rounded, size: 48, color: cs.primary),
                ),
              )
            else
              Container(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                child: Center(child: Icon(Icons.image_rounded, size: 48, color: cs.primary)),
              ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner['title'] ?? 'Untitled',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _positionLabel(position),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    _ActionButton(icon: Icons.edit_rounded, tooltip: 'Edit', onPressed: onEdit),
                    _ActionButton(
                      icon: isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      tooltip: isActive ? 'Deactivate' : 'Activate',
                      onPressed: onToggle,
                    ),
                    _ActionButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', onPressed: onDelete, isDestructive: true),
                  ],
                ),
              ),
            ),
            // Status + position badges
            Positioned(
              top: 8, right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Order: ${banner['sortOrder'] ?? 0}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _positionLabel(String position) {
    return switch (position) {
      'home_slider' => 'Home Slider',
      'category_banner' => 'Category',
      'flash_sale' => 'Flash Sale',
      _ => position,
    };
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _ActionButton({required this.icon, required this.tooltip, required this.onPressed, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, color: isDestructive ? const Color(0xFFFF6B6B) : Colors.white, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
