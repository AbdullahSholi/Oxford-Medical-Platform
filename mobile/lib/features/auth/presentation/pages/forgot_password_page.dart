import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthForgotPasswordRequested(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loginForgotPassword)),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is AuthOtpSent) {
            context.push('/auth/otp', extra: state.email);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.verticalGapXxl,
                Text(
                  context.l10n.loginForgotPassword,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                AppSpacing.verticalGapSm,
                Text(
                  'Enter your email address and we will send you a verification code.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  controller: _emailController,
                  label: context.l10n.loginEmail,
                  hint: 'doctor@clinic.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.email,
                  onSubmitted: (_) => _onSubmit(),
                ),
                AppSpacing.verticalGapXl,
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return AppButton(
                      label: 'Send OTP',
                      isLoading: state is AuthLoading,
                      onPressed: _onSubmit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
