import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class CategoryFormPage extends StatefulWidget {
  final String? id;
  const CategoryFormPage({super.key, this.id});
  bool get isEdit => id != null;
  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _iconUrl = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  String? _parentId;
  bool _loading = false;
  bool _saving = false;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.isEdit) _loadCategory();
  }

  @override
  void dispose() {
    _name.dispose(); _description.dispose(); _iconUrl.dispose(); _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/categories');
      setState(() => _categories = (res['data'] as List?) ?? []);
    } catch (_) {}
  }

  Future<void> _loadCategory() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/categories');
      final categories = (res['data'] as List?) ?? [];
      // Find the category — could be top-level or nested
      Map<String, dynamic>? found;
      for (final c in categories) {
        final cat = c as Map<String, dynamic>;
        if (cat['id'] == widget.id) { found = cat; break; }
        for (final child in (cat['children'] as List? ?? [])) {
          if ((child as Map<String, dynamic>)['id'] == widget.id) { found = child; break; }
        }
        if (found != null) break;
      }
      if (found != null) {
        _name.text = found['name'] ?? '';
        _description.text = found['description'] ?? '';
        _iconUrl.text = found['iconUrl'] ?? '';
        _sortOrder.text = '${found['sortOrder'] ?? 0}';
        _parentId = found['parentId'] as String?;
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
        'name': _name.text.trim(),
        if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
        if (_iconUrl.text.trim().isNotEmpty) 'iconUrl': _iconUrl.text.trim(),
        if (_parentId != null) 'parentId': _parentId,
        'sortOrder': int.tryParse(_sortOrder.text.trim()) ?? 0,
      };
      if (widget.isEdit) {
        await api.patch('/admin/categories/${widget.id}', data: data);
      } else {
        await api.post('/admin/categories', data: data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category ${widget.isEdit ? "updated" : "created"}!'), backgroundColor: const Color(0xFF10B981)),
        );
        context.go('/categories');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    setState(() => _saving = false);
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
              IconButton(onPressed: () => context.go('/categories'), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text(widget.isEdit ? 'Edit Category' : 'New Category',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          Text('Category Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(labelText: 'Category Name *', prefixIcon: Icon(Icons.label_rounded)),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _description,
                            decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded)),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: TextFormField(
                              controller: _iconUrl,
                              decoration: const InputDecoration(labelText: 'Icon URL', prefixIcon: Icon(Icons.image_rounded), hintText: 'https://...'),
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(
                              controller: _sortOrder,
                              decoration: const InputDecoration(labelText: 'Sort Order', prefixIcon: Icon(Icons.sort)),
                              keyboardType: TextInputType.number,
                            )),
                          ]),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String?>(
                            value: _parentId,
                            decoration: const InputDecoration(labelText: 'Parent Category (optional)', prefixIcon: Icon(Icons.account_tree_rounded)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None (Top Level)')),
                              ..._categories
                                  .where((c) => (c as Map<String, dynamic>)['id'] != widget.id)
                                  .map((c) {
                                final cat = c as Map<String, dynamic>;
                                return DropdownMenuItem(value: cat['id'] as String, child: Text(cat['name'] as String? ?? ''));
                              }),
                            ],
                            onChanged: (v) => setState(() => _parentId = v),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_rounded),
                              label: Text(widget.isEdit ? 'Update Category' : 'Create Category'),
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
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _iconUrl.text.trim().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(_iconUrl.text.trim(), fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(Icons.category, size: 36, color: Theme.of(context).colorScheme.primary)),
                                  )
                                : Icon(Icons.category, size: 36, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _name.text.trim().isNotEmpty ? _name.text.trim() : 'Category Name',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_description.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _description.text.trim(),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_parentId != null)
                          Center(
                            child: Chip(
                              avatar: const Icon(Icons.account_tree, size: 16),
                              label: Text('Sub-category of ${_categories.firstWhere(
                                (c) => (c as Map<String, dynamic>)['id'] == _parentId,
                                orElse: () => {'name': 'Unknown'},
                              )['name'] ?? 'Unknown'}'),
                            ),
                          ),
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
