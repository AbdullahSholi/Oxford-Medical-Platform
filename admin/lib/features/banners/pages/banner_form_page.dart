import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class BannerFormPage extends StatefulWidget {
  final String? id;
  const BannerFormPage({super.key, this.id});
  bool get isEdit => id != null;
  @override
  State<BannerFormPage> createState() => _BannerFormPageState();
}

class _BannerFormPageState extends State<BannerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _imageUrl = TextEditingController();
  final _linkTarget = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  String _position = 'home_slider';
  String _linkType = 'none';
  bool _isActive = true;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadBanner();
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _imageUrl.dispose();
    _linkTarget.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthCubit>().apiClient;
      final res = await api.get('/admin/banners');
      final banners = (res['data'] as List?) ?? [];
      final banner = banners.firstWhere(
        (b) => (b as Map<String, dynamic>)['id'] == widget.id,
        orElse: () => null,
      );
      if (banner != null) {
        final b = banner as Map<String, dynamic>;
        _title.text = b['title'] ?? '';
        _subtitle.text = b['subtitle'] ?? '';
        _imageUrl.text = b['imageUrl'] ?? '';
        _linkTarget.text = b['linkTarget'] ?? '';
        _sortOrder.text = '${b['sortOrder'] ?? 0}';
        _position = b['position'] ?? 'home_slider';
        _linkType = b['linkType'] ?? 'none';
        _isActive = b['isActive'] ?? true;
        if (b['startsAt'] != null) _startsAt = DateTime.tryParse(b['startsAt']);
        if (b['endsAt'] != null) _endsAt = DateTime.tryParse(b['endsAt']);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = context.read<AuthCubit>().apiClient;
      final data = <String, dynamic>{
        'imageUrl': _imageUrl.text.trim(),
        'position': _position,
        'sortOrder': int.tryParse(_sortOrder.text.trim()) ?? 0,
        if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
        if (_subtitle.text.trim().isNotEmpty) 'subtitle': _subtitle.text.trim(),
        if (_linkType != 'none') 'linkType': _linkType,
        if (_linkTarget.text.trim().isNotEmpty) 'linkTarget': _linkTarget.text.trim(),
        if (_startsAt != null) 'startsAt': _startsAt!.toIso8601String(),
        if (_endsAt != null) 'endsAt': _endsAt!.toIso8601String(),
      };
      if (widget.isEdit) {
        data['isActive'] = _isActive;
        await api.patch('/admin/banners/${widget.id}', data: data);
      } else {
        await api.post('/admin/banners', data: data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banner ${widget.isEdit ? "updated" : "created"}!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        context.go('/banners');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startsAt ?? DateTime.now()) : (_endsAt ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isStart ? _startsAt = picked : _endsAt = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => context.go('/banners'), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text(widget.isEdit ? 'Edit Banner' : 'New Banner',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form card
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Banner Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _imageUrl,
                            decoration: const InputDecoration(
                              labelText: 'Image URL *',
                              hintText: 'https://example.com/banner.jpg',
                              prefixIcon: Icon(Icons.image_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Image URL is required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: TextFormField(
                              controller: _title,
                              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(
                              controller: _subtitle,
                              decoration: const InputDecoration(labelText: 'Subtitle', prefixIcon: Icon(Icons.subtitles)),
                            )),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: DropdownButtonFormField<String>(
                              value: _position,
                              decoration: const InputDecoration(labelText: 'Position', prefixIcon: Icon(Icons.place_rounded)),
                              items: const [
                                DropdownMenuItem(value: 'home_slider', child: Text('Home Slider')),
                                DropdownMenuItem(value: 'category_banner', child: Text('Category Banner')),
                                DropdownMenuItem(value: 'flash_sale', child: Text('Flash Sale')),
                              ],
                              onChanged: (v) => setState(() => _position = v!),
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(
                              controller: _sortOrder,
                              decoration: const InputDecoration(labelText: 'Sort Order', prefixIcon: Icon(Icons.sort)),
                              keyboardType: TextInputType.number,
                            )),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: DropdownButtonFormField<String>(
                              value: _linkType,
                              decoration: const InputDecoration(labelText: 'Link Type', prefixIcon: Icon(Icons.link)),
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('None')),
                                DropdownMenuItem(value: 'product', child: Text('Product')),
                                DropdownMenuItem(value: 'category', child: Text('Category')),
                                DropdownMenuItem(value: 'url', child: Text('External URL')),
                              ],
                              onChanged: (v) => setState(() => _linkType = v!),
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(
                              controller: _linkTarget,
                              decoration: InputDecoration(
                                labelText: _linkType == 'url' ? 'URL' : 'Target ID',
                                prefixIcon: const Icon(Icons.open_in_new),
                                enabled: _linkType != 'none',
                              ),
                            )),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Starts At'),
                              subtitle: Text(_formatDate(_startsAt)),
                              trailing: _startsAt != null
                                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _startsAt = null))
                                  : null,
                              onTap: () => _pickDate(true),
                            )),
                            Expanded(child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Ends At'),
                              subtitle: Text(_formatDate(_endsAt)),
                              trailing: _endsAt != null
                                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _endsAt = null))
                                  : null,
                              onTap: () => _pickDate(false),
                            )),
                          ]),
                          if (widget.isEdit) ...[
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Active'),
                              subtitle: Text(_isActive ? 'Banner is visible' : 'Banner is hidden'),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_rounded),
                              label: Text(widget.isEdit ? 'Update Banner' : 'Create Banner'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Preview card
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        AspectRatio(
                          aspectRatio: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _imageUrl.text.trim().isNotEmpty
                                ? Image.network(
                                    _imageUrl.text.trim(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholder(context),
                                  )
                                : _placeholder(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_title.text.trim().isNotEmpty)
                          Text(_title.text.trim(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (_subtitle.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_subtitle.text.trim(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: [
                          Chip(
                            avatar: const Icon(Icons.place, size: 16),
                            label: Text(_positionLabel(_position)),
                          ),
                          if (_linkType != 'none')
                            Chip(
                              avatar: const Icon(Icons.link, size: 16),
                              label: Text(_linkType),
                            ),
                        ]),
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

  Widget _placeholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 8),
            Text('Enter image URL to preview', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _positionLabel(String position) {
    return switch (position) {
      'home_slider' => 'Home Slider',
      'category_banner' => 'Category Banner',
      'flash_sale' => 'Flash Sale',
      _ => position,
    };
  }
}
