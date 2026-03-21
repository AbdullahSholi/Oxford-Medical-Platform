import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../routing/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _licenseController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  bool _obscurePassword = true;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthRegisterSubmitted(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
            specialty: _specialtyController.text.trim().isNotEmpty
                ? _specialtyController.text.trim()
                : null,
            licenseNumber: _licenseController.text.trim().isNotEmpty
                ? _licenseController.text.trim()
                : null,
            clinicName: _clinicNameController.text.trim().isNotEmpty
                ? _clinicNameController.text.trim()
                : null,
            clinicAddress: _clinicAddressController.text.trim().isNotEmpty
                ? _clinicAddressController.text.trim()
                : null,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showErrorDialog(
              title: 'Registration Failed',
              message: state.message,
            );
          } else if (state is AuthRegistrationSuccess) {
            context.showSuccessDialog(
              title: 'Registration Successful',
              message: 'Your account has been created! Please wait for admin approval.',
              confirmLabel: 'Got it',
            ).then((_) {
              if (context.mounted) context.go(RouteNames.pendingApproval);
            });
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 32,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryDarkGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusXxl),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.registerTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your medical professional account',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Step indicators
                    Row(
                      children: List.generate(3, (index) {
                        final isActive = index <= _currentStep;
                        final isCompleted = index < _currentStep;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step ${_currentStep + 1} of 3 — ${_stepTitle(_currentStep)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Form content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStepContent(_currentStep),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                    AppSpacing.horizontalGapMd,
                  ],
                  Expanded(
                    flex: _currentStep > 0 ? 2 : 1,
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return AppButton(
                          label: _currentStep < 2
                              ? 'Continue'
                              : context.l10n.registerButton,
                          isLoading: state is AuthLoading,
                          variant: AppButtonVariant.gradient,
                          onPressed: () {
                            if (_currentStep < 2) {
                              setState(() => _currentStep++);
                            } else {
                              _onSubmit();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.registerHaveAccount,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.login),
                    child: Text(context.l10n.loginTitle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle(int step) => switch (step) {
    0 => 'Personal Info',
    1 => 'Professional Details',
    2 => 'Clinic Info',
    _ => '',
  };

  Widget _buildStepContent(int step) {
    return switch (step) {
      0 => Column(
        key: const ValueKey(0),
        children: [
          AppTextField(
            controller: _nameController,
            label: context.l10n.registerFullName,
            prefixIcon: const Icon(Icons.person_outlined),
            validator: (v) => Validators.required(v, 'Name'),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.verticalGapLg,
          AppTextField(
            controller: _emailController,
            label: context.l10n.loginEmail,
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.verticalGapLg,
          AppTextField(
            controller: _phoneController,
            label: context.l10n.registerPhone,
            prefixIcon: const Icon(Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.verticalGapLg,
          AppTextField(
            controller: _passwordController,
            label: context.l10n.loginPassword,
            prefixIcon: const Icon(Icons.lock_outlined),
            obscureText: _obscurePassword,
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ],
      ),
      1 => Column(
        key: const ValueKey(1),
        children: [
          AppTextField(
            controller: _specialtyController,
            label: context.l10n.registerSpecialty,
            prefixIcon: const Icon(Icons.medical_services_outlined),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.verticalGapLg,
          AppTextField(
            controller: _licenseController,
            label: context.l10n.registerLicenseNumber,
            prefixIcon: const Icon(Icons.badge_outlined),
            validator: Validators.licenseNumber,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
      2 => Column(
        key: const ValueKey(2),
        children: [
          AppTextField(
            controller: _clinicNameController,
            label: context.l10n.registerClinicName,
            prefixIcon: const Icon(Icons.local_hospital_outlined),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.verticalGapLg,
          AppTextField(
            controller: _clinicAddressController,
            label: context.l10n.registerClinicAddress,
            prefixIcon: const Icon(Icons.location_on_outlined),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
