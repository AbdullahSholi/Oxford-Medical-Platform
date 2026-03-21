import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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
    context.showSuccessSnackBar('OTP code has been resent to ${widget.email}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showErrorDialog(
              title: 'Verification Failed',
              message: state.message,
            );
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
                  bottom: 40,
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
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.sms_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.otpTitle,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.otpSubtitle(widget.email),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // OTP form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
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
                          variant: AppButtonVariant.gradient,
                          isLoading: state is AuthLoading,
                          onPressed: _onVerify,
                        );
                      },
                    ),
                    AppSpacing.verticalGapLg,
                    // Resend timer
                    Center(
                      child: _resendCooldown > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${context.l10n.otpResend} (${_resendCooldown}s)',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton.icon(
                              onPressed: _onResend,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(context.l10n.otpResend),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
