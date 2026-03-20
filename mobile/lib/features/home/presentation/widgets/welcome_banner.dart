import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class WelcomeBanner extends StatelessWidget {
  final String doctorName;

  const WelcomeBanner({super.key, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeGreeting(doctorName),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                AppSpacing.verticalGapXs,
                Text(
                  context.l10n.welcomeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
