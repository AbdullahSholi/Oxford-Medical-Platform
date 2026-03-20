import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = di.sl<ApiClient>();
      final response = await apiClient.get<List<dynamic>>(
        ApiEndpoints.doctorAddresses,
        parser: (data) => data is List ? data : (data as Map<String, dynamic>)['data'] as List? ?? [],
      );
      if (response.success && response.data != null) {
        setState(() {
          _addresses = response.data!.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = response.error?.message ?? 'Failed to load addresses'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load addresses'; _loading = false; });
    }
  }

  Future<void> _deleteAddress(String id) async {
    final confirmed = await context.showConfirmDialog(title: 'Delete Address', message: 'Are you sure you want to delete this address?');
    if (confirmed != true) return;
    try {
      final apiClient = di.sl<ApiClient>();
      await apiClient.delete<void>('${ApiEndpoints.doctorAddresses}/$id', parser: (_) {});
      _loadAddresses();
      if (mounted) context.showSnackBar('Address deleted');
    } catch (e) {
      if (mounted) context.showSnackBar('Failed to delete address');
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? address}) {
    final labelCtrl = TextEditingController(text: address?['label'] as String? ?? '');
    final streetCtrl = TextEditingController(text: address?['streetAddress'] as String? ?? '');
    final cityCtrl = TextEditingController(text: address?['city'] as String? ?? '');
    final stateCtrl = TextEditingController(text: address?['state'] as String? ?? '');
    final zipCtrl = TextEditingController(text: address?['postalCode'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: address?['phone'] as String? ?? '');
    bool isDefault = address?['isDefault'] as bool? ?? false;
    final isEdit = address != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Address' : 'Add Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g. Clinic, Home)')),
                TextField(controller: streetCtrl, decoration: const InputDecoration(labelText: 'Street Address')),
                TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
                TextField(controller: zipCtrl, decoration: const InputDecoration(labelText: 'Postal Code')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                CheckboxListTile(
                  value: isDefault,
                  onChanged: (v) => setDialogState(() => isDefault = v ?? false),
                  title: const Text('Default Address'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final data = {
                  'label': labelCtrl.text.trim(),
                  'recipientName': 'Dr. Ahmad Khalil', // Fallback for testing
                  'streetAddress': streetCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'state': stateCtrl.text.trim(),
                  'postalCode': zipCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'isDefault': isDefault,
                };
                Navigator.pop(ctx);
                final apiClient = di.sl<ApiClient>();
                try {
                  if (isEdit) {
                    await apiClient.patch<void>(
                      '${ApiEndpoints.doctorAddresses}/${address!['id']}',
                      data: data,
                      parser: (_) {},
                    );
                  } else {
                    await apiClient.post<void>(
                      ApiEndpoints.doctorAddresses,
                      data: data,
                      parser: (_) {},
                    );
                  }
                  _loadAddresses();
                  if (mounted) context.showSnackBar(isEdit ? 'Address updated' : 'Address added');
                } catch (e) {
                  if (mounted) context.showSnackBar('Failed to save address');
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const AppLoading()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadAddresses)
              : _addresses.isEmpty
                  ? const AppEmptyState(title: 'No addresses yet', icon: Icons.location_off_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => AppSpacing.verticalGapMd,
                      itemBuilder: (_, index) {
                        final addr = _addresses[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(addr['label'] as String? ?? 'Address'),
                            subtitle: Text([addr['streetAddress'], addr['city'], addr['state']].where((s) => s != null && s.toString().isNotEmpty).join(', ')),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (addr['isDefault'] == true)
                                  const Chip(label: Text('Default', style: TextStyle(fontSize: 11))),
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showAddEditDialog(address: addr)),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _deleteAddress(addr['id'] as String)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
