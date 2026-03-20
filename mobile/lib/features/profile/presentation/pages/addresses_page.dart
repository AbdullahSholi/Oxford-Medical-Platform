import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    isEdit ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(controller: labelCtrl, label: 'Label', hint: 'e.g. Clinic, Home', prefixIcon: const Icon(Icons.label_outlined)),
                  AppSpacing.verticalGapLg,
                  AppTextField(controller: streetCtrl, label: 'Street Address', prefixIcon: const Icon(Icons.location_on_outlined)),
                  AppSpacing.verticalGapLg,
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: cityCtrl, label: 'City', prefixIcon: const Icon(Icons.location_city_outlined))),
                      AppSpacing.horizontalGapMd,
                      Expanded(child: AppTextField(controller: stateCtrl, label: 'State')),
                    ],
                  ),
                  AppSpacing.verticalGapLg,
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: zipCtrl, label: 'Postal Code', keyboardType: TextInputType.number)),
                      AppSpacing.horizontalGapMd,
                      Expanded(child: AppTextField(controller: phoneCtrl, label: 'Phone', keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_outlined))),
                    ],
                  ),
                  AppSpacing.verticalGapLg,
                  GestureDetector(
                    onTap: () => setDialogState(() => isDefault = !isDefault),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDefault ? AppColors.primarySurface : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isDefault ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDefault ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: isDefault ? AppColors.primary : AppColors.textHint,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text('Set as default address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalGapXl,
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      AppSpacing.horizontalGapMd,
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: isEdit ? 'Update' : 'Add Address',
                          variant: AppButtonVariant.gradient,
                          onPressed: () async {
                            final data = {
                              'label': labelCtrl.text.trim(),
                              'recipientName': 'Dr.',
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Addresses',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const AppLoading()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadAddresses)
              : _addresses.isEmpty
                  ? const AppEmptyState(title: 'No addresses yet', icon: Icons.location_off_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => AppSpacing.verticalGapMd,
                      itemBuilder: (_, index) {
                        final addr = _addresses[index];
                        final isDefault = addr['isDefault'] == true;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            boxShadow: AppSpacing.shadowSm,
                            border: isDefault
                                ? Border.all(color: AppColors.primary.withOpacity(0.3))
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDefault
                                          ? AppColors.primarySurface
                                          : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: isDefault ? AppColors.primary : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              addr['label'] as String? ?? 'Address',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primarySurface,
                                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                                ),
                                                child: const Text(
                                                  'Default',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [addr['streetAddress'], addr['city'], addr['state']]
                                              .where((s) => s != null && s.toString().isNotEmpty)
                                              .join(', '),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: AppColors.divider),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showAddEditDialog(address: addr),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit', style: TextStyle(fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _deleteAddress(addr['id'] as String),
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('Delete', style: TextStyle(fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
