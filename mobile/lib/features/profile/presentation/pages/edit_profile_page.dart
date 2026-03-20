import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _clinicNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _clinicAddressController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    final doctor = state is AuthAuthenticated ? state.doctor : null;
    _nameController = TextEditingController(text: doctor?.fullName ?? '');
    _phoneController = TextEditingController(text: doctor?.phone ?? '');
    _specialtyController = TextEditingController(text: doctor?.specialty ?? '');
    _clinicNameController = TextEditingController(text: doctor?.clinicName ?? '');
    _cityController = TextEditingController(text: doctor?.city ?? '');
    _clinicAddressController = TextEditingController(text: doctor?.clinicAddress ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _clinicNameController.dispose();
    _cityController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final apiClient = di.sl<ApiClient>();
      final data = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      if (_specialtyController.text.trim().isNotEmpty) {
        data['specialty'] = _specialtyController.text.trim();
      }
      if (_clinicNameController.text.trim().isNotEmpty) {
        data['clinicName'] = _clinicNameController.text.trim();
      }
      if (_cityController.text.trim().isNotEmpty) {
        data['city'] = _cityController.text.trim();
      }
      if (_clinicAddressController.text.trim().isNotEmpty) {
        data['clinicAddress'] = _clinicAddressController.text.trim();
      }

      final response = await apiClient.patch<Map<String, dynamic>>(
        ApiEndpoints.updateProfile,
        data: data,
        parser: (data) => data as Map<String, dynamic>,
      );
      if (mounted) {
        if (response.success) {
          context.read<AuthBloc>().add(const AuthCheckRequested());
          context.showSnackBar('Profile updated successfully');
          Navigator.of(context).pop();
        } else {
          context.showSnackBar(response.error?.message ?? 'Failed to update profile');
        }
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Failed to update profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().length < 3
                    ? 'Name must be at least 3 characters'
                    : null,
              ),
              AppSpacing.verticalGapMd,
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+201234567890',
                ),
                keyboardType: TextInputType.phone,
              ),
              AppSpacing.verticalGapMd,
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
              AppSpacing.verticalGapMd,
              TextFormField(
                controller: _clinicNameController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              AppSpacing.verticalGapMd,
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              AppSpacing.verticalGapMd,
              TextFormField(
                controller: _clinicAddressController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
              ),
              AppSpacing.verticalGapXl,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
