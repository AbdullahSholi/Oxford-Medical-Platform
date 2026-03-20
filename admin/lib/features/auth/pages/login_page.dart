import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is Authenticated) {
                context.go('/');
              } else if (state is Unauthenticated && state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error!), backgroundColor: cs.error),
                );
              }
            },
            builder: (context, state) {
              final loading = state is AuthLoading;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings, size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('MedOrder Admin', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Sign in to manage your platform', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    enabled: !loading,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: loading ? null : _login,
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _login() {
    if (_email.text.isEmpty || _password.text.isEmpty) return;
    context.read<AuthCubit>().login(_email.text.trim(), _password.text);
  }
}
