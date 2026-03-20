import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  int _resendCooldown = AppConstants.otpResendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = AppConstants.otpResendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _onVerify() {
    final otp = _otpController.text.trim();
    if (otp.length == AppConstants.otpLength) {
      context.push('/auth/reset-password', extra: {
        'email': widget.email,
        'otp': otp,
      });
    }
  }

  void _onResend() {
    context.read<AuthBloc>().add(AuthOtpResendRequested(email: widget.email));
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.verticalGapXxl,
              Text(
                context.l10n.otpTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              AppSpacing.verticalGapSm,
              Text(
                context.l10n.otpSubtitle(widget.email),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),
              AppTextField(
                controller: _otpController,
                hint: '000000',
                keyboardType: TextInputType.number,
                maxLength: AppConstants.otpLength,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onVerify(),
              ),
              AppSpacing.verticalGapXl,
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return AppButton(
                    label: context.l10n.otpVerify,
                    isLoading: state is AuthLoading,
                    onPressed: _onVerify,
                  );
                },
              ),
              AppSpacing.verticalGapLg,
              Center(
                child: _resendCooldown > 0
                    ? Text(
                        '${context.l10n.otpResend} (${_resendCooldown}s)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      )
                    : TextButton(
                        onPressed: _onResend,
                        child: Text(context.l10n.otpResend),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
