import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal section
              _SectionHeader(title: 'Personal Information', icon: Icons.person_outline_rounded),
              AppSpacing.verticalGapLg,
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: const Icon(Icons.person_outlined),
                validator: (v) => v == null || v.trim().length < 3
                    ? 'Name must be at least 3 characters'
                    : null,
              ),
              AppSpacing.verticalGapLg,
              AppTextField(
                controller: _phoneController,
                label: 'Phone',
                hint: '+201234567890',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              AppSpacing.verticalGapXl,

              // Professional section
              _SectionHeader(title: 'Professional Details', icon: Icons.medical_services_outlined),
              AppSpacing.verticalGapLg,
              AppTextField(
                controller: _specialtyController,
                label: 'Specialty',
                prefixIcon: const Icon(Icons.medical_services_outlined),
              ),
              AppSpacing.verticalGapXl,

              // Clinic section
              _SectionHeader(title: 'Clinic Information', icon: Icons.local_hospital_outlined),
              AppSpacing.verticalGapLg,
              AppTextField(
                controller: _clinicNameController,
                label: 'Clinic Name',
                prefixIcon: const Icon(Icons.local_hospital_outlined),
              ),
              AppSpacing.verticalGapLg,
              AppTextField(
                controller: _cityController,
                label: 'City',
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              AppSpacing.verticalGapLg,
              AppTextField(
                controller: _clinicAddressController,
                label: 'Clinic Address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 2,
              ),
              AppSpacing.verticalGapXxl,
              AppButton(
                label: 'Save Changes',
                variant: AppButtonVariant.gradient,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
