import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routing/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is AuthAuthenticated) {
            context.go(RouteNames.home);
          } else if (state is AuthPendingApproval) {
            context.go(RouteNames.pendingApproval);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Text(
                  context.l10n.loginTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                AppSpacing.verticalGapSm,
                Text(
                  context.l10n.welcomeSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 40),
                const LoginForm(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.loginNoAccount),
                    AppButton(
                      label: context.l10n.registerTitle,
                      variant: AppButtonVariant.text,
                      width: null,
                      onPressed: () => context.go(RouteNames.register),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
