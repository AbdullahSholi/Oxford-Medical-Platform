import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: Text(context.l10n.registerTitle),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is AuthRegistrationSuccess) {
            context.go(RouteNames.pendingApproval);
          }
        },
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _onSubmit();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return AppButton(
                            label: _currentStep < 2
                                ? 'Next'
                                : context.l10n.registerButton,
                            isLoading: state is AuthLoading,
                            onPressed: details.onStepContinue,
                          );
                        },
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      AppSpacing.horizontalGapMd,
                      Expanded(
                        child: AppButton(
                          label: 'Back',
                          variant: AppButtonVariant.secondary,
                          onPressed: details.onStepCancel,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Personal Info'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
                content: Column(
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
              ),
              Step(
                title: const Text('Professional Details'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
                content: Column(
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
              ),
              Step(
                title: const Text('Clinic Info'),
                isActive: _currentStep >= 2,
                content: Column(
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.registerHaveAccount),
              TextButton(
                onPressed: () => context.go(RouteNames.login),
                child: Text(context.l10n.loginTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
