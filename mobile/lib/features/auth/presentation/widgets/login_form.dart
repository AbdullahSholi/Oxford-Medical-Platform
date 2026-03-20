import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailController,
            label: context.l10n.loginEmail,
            hint: 'doctor@clinic.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: Validators.email,
          ),
          AppSpacing.verticalGapLg,
          AppTextField(
            controller: _passwordController,
            label: context.l10n.loginPassword,
            hint: '********',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: Validators.password,
            onSubmitted: (_) => _onSubmit(),
          ),
          AppSpacing.verticalGapSm,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/auth/forgot-password'),
              child: Text(context.l10n.loginForgotPassword),
            ),
          ),
          AppSpacing.verticalGapXl,
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return AppButton(
                label: context.l10n.loginButton,
                isLoading: state is AuthLoading,
                onPressed: _onSubmit,
              );
            },
          ),
        ],
      ),
    );
  }
}
