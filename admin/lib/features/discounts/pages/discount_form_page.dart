import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class DiscountFormPage extends StatefulWidget {
  final String? id;
  const DiscountFormPage({super.key, this.id});
  bool get isEdit => id != null;
  @override
  State<DiscountFormPage> createState() => _DiscountFormPageState();
}

class _DiscountFormPageState extends State<DiscountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _description = TextEditingController();
  final _value = TextEditingController();
  final _minOrder = TextEditingController();
  final _maxDiscount = TextEditingController();
  final _usageLimit = TextEditingController();
  final _perUserLimit = TextEditingController(text: '1');
  String _type = 'percentage';
  DateTime _startsAt = DateTime.now();
  DateTime _endsAt = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose(); _description.dispose(); _value.dispose();
    _minOrder.dispose(); _maxDiscount.dispose(); _usageLimit.dispose(); _perUserLimit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'code': _code.text.trim(),
        'type': _type,
        'value': double.parse(_value.text.trim()),
        'startsAt': _startsAt.toIso8601String(),
        'endsAt': _endsAt.toIso8601String(),
        'perUserLimit': int.parse(_perUserLimit.text.trim()),
        if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
        if (_minOrder.text.trim().isNotEmpty) 'minOrderAmount': double.parse(_minOrder.text.trim()),
        if (_maxDiscount.text.trim().isNotEmpty) 'maxDiscount': double.parse(_maxDiscount.text.trim()),
        if (_usageLimit.text.trim().isNotEmpty) 'usageLimit': int.parse(_usageLimit.text.trim()),
      };
      final api = context.read<AuthCubit>().apiClient;
      if (widget.isEdit) {
        await api.patch('/admin/discounts/${widget.id}', data: data);
      } else {
        await api.post('/admin/discounts', data: data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discount saved!'), backgroundColor: Color(0xFF10B981)));
        context.go('/discounts');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    setState(() => _saving = false);
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startsAt : _endsAt,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isStart ? _startsAt = picked : _endsAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => context.go('/discounts'), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text(widget.isEdit ? 'Edit Discount' : 'New Discount',
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
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _code,
                        decoration: const InputDecoration(labelText: 'Discount Code *'),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v != null && v.trim().length >= 3 ? null : 'Min 3 characters',
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                          DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                        ],
                        onChanged: (v) => setState(() => _type = v!),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(
                        controller: _value,
                        decoration: InputDecoration(labelText: 'Value *', suffixText: _type == 'percentage' ? '%' : 'EGP'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v != null && double.tryParse(v.trim()) != null ? null : 'Required',
                      )),
                    ]),
                    const SizedBox(height: 16),
                    TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _minOrder, decoration: const InputDecoration(labelText: 'Min Order Amount'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: _maxDiscount, decoration: const InputDecoration(labelText: 'Max Discount'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: _usageLimit, decoration: const InputDecoration(labelText: 'Usage Limit'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: _perUserLimit, decoration: const InputDecoration(labelText: 'Per User Limit'), keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: ListTile(
                        title: const Text('Starts At'),
                        subtitle: Text('${_startsAt.day}/${_startsAt.month}/${_startsAt.year}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(true),
                      )),
                      Expanded(child: ListTile(
                        title: const Text('Ends At'),
                        subtitle: Text('${_endsAt.day}/${_endsAt.month}/${_endsAt.year}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(false),
                      )),
                    ]),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(widget.isEdit ? 'Update Discount' : 'Create Discount'),
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
