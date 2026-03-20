import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) return const SizedBox.shrink();
          final doctor = state.doctor;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(doctor.fullName.initials, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                AppSpacing.verticalGapMd,
                Text(doctor.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(doctor.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                if (doctor.specialty != null) Text(doctor.specialty!, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                AppSpacing.verticalGapXl,
                _MenuItem(icon: Icons.person_outlined, label: context.l10n.profileEdit, onTap: () => context.push('/profile/edit')),
                _MenuItem(icon: Icons.location_on_outlined, label: context.l10n.profileAddresses, onTap: () => context.push('/profile/addresses')),
                _MenuItem(icon: Icons.receipt_long_outlined, label: context.l10n.profileOrders, onTap: () => context.push('/orders')),
                _MenuItem(icon: Icons.favorite_border_rounded, label: context.l10n.profileWishlist, onTap: () => context.push('/wishlist')),
                _MenuItem(icon: Icons.notifications_outlined, label: context.l10n.profileNotifications, onTap: () => context.push('/notifications')),
                BlocBuilder<LocaleCubit, Locale>(
                  builder: (context, locale) {
                    final isArabic = locale.languageCode == 'ar';
                    return _MenuItem(
                      icon: Icons.language_rounded,
                      label: isArabic ? 'English' : 'العربية',
                      onTap: () => context.read<LocaleCubit>().toggleLocale(),
                    );
                  },
                ),
                AppSpacing.verticalGapXl,
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: context.l10n.profileLogout,
                  color: AppColors.error,
                  onTap: () async {
                    final confirmed = await context.showConfirmDialog(title: context.l10n.profileLogout, message: context.l10n.profileLogoutConfirm);
                    if (confirmed == true && context.mounted) {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? AppColors.textPrimary),
    title: Text(label, style: TextStyle(color: color)),
    trailing: Icon(Icons.chevron_right_rounded, color: color ?? AppColors.textHint),
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
  );
}
