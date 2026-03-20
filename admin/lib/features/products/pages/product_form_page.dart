import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class ProductFormPage extends StatefulWidget {
  final String? id;
  const ProductFormPage({super.key, this.id});
  bool get isEdit => id != null;
  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _stock = TextEditingController();
  String? _categoryId;
  bool _isActive = true;
  bool _loading = false;
  bool _saving = false;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.isEdit) _loadProduct();
  }

  @override
  void dispose() {
    _name.dispose(); _sku.dispose(); _description.dispose();
    _price.dispose(); _salePrice.dispose(); _stock.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/categories');
      setState(() => _categories = (res['data'] as List?) ?? []);
    } catch (_) {}
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthCubit>().apiClient.get('/products/${widget.id}');
      final p = res['data'] as Map<String, dynamic>;
      _name.text = p['name'] ?? '';
      _sku.text = p['sku'] ?? '';
      _description.text = p['description'] ?? '';
      _price.text = '${p['price'] ?? ''}';
      _salePrice.text = p['salePrice'] != null ? '${p['salePrice']}' : '';
      _stock.text = '${p['stock'] ?? ''}';
      _categoryId = p['categoryId'] as String?;
      _isActive = p['isActive'] ?? true;
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = context.read<AuthCubit>().apiClient;
      final data = {
        'name': _name.text.trim(),
        'sku': _sku.text.trim(),
        'description': _description.text.trim(),
        'price': double.parse(_price.text.trim()),
        'stock': int.parse(_stock.text.trim()),
        'isActive': _isActive,
        if (_categoryId != null) 'categoryId': _categoryId,
        if (_salePrice.text.trim().isNotEmpty) 'salePrice': double.parse(_salePrice.text.trim()),
      };
      if (widget.isEdit) {
        await api.patch('/admin/products/${widget.id}', data: data);
      } else {
        await api.post('/admin/products', data: data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product ${widget.isEdit ? "updated" : "created"}!'), backgroundColor: const Color(0xFF10B981)),
        );
        context.go('/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
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
              IconButton(onPressed: () => context.go('/products'), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text(widget.isEdit ? 'Edit Product' : 'New Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Product Name *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(
                          controller: _sku,
                          decoration: const InputDecoration(labelText: 'SKU *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: _price,
                          decoration: const InputDecoration(labelText: 'Price (EGP) *', prefixText: 'EGP '),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (double.tryParse(v.trim()) == null) return 'Invalid number';
                            return null;
                          },
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(
                          controller: _salePrice,
                          decoration: const InputDecoration(labelText: 'Sale Price (optional)', prefixText: 'EGP '),
                          keyboardType: TextInputType.number,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(
                          controller: _stock,
                          decoration: const InputDecoration(labelText: 'Stock *'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (int.tryParse(v.trim()) == null) return 'Invalid number';
                            return null;
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _categoryId,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: _categories.map((c) {
                              final cat = c as Map<String, dynamic>;
                              return DropdownMenuItem(value: cat['id'] as String, child: Text(cat['name'] as String? ?? ''));
                            }).toList(),
                            onChanged: (v) => setState(() => _categoryId = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 160,
                          child: SwitchListTile(
                            title: const Text('Active'),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(widget.isEdit ? 'Update Product' : 'Create Product'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
