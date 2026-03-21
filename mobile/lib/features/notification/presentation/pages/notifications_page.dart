import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../bloc/notification_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const NotificationsFetched());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.notificationsTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<NotificationBloc>().add(const NotificationsAllMarkedRead());
              context.showSuccessSnackBar('All notifications marked as read');
            },
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark all read', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationError) {
            context.showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) return const AppLoading();
          if (state is NotificationError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<NotificationBloc>().add(const NotificationsFetched()),
            );
          }
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return AppEmptyState(
                title: context.l10n.notificationsEmpty,
                icon: Icons.notifications_off_outlined,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final n = state.notifications[index];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error),
                  ),
                  onDismissed: (_) {
                    context.read<NotificationBloc>().add(NotificationDeleted(n.id));
                    context.showSnackBar('Notification deleted');
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.surface : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: n.isRead
                          ? Border.all(color: AppColors.divider, width: 1)
                          : Border.all(color: AppColors.primaryLight.withOpacity(0.3), width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!n.isRead) context.read<NotificationBloc>().add(NotificationMarkedRead(n.id));
                          final orderId = n.data?['orderId'] as String?;
                          if (orderId != null) context.push('/orders/$orderId');
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: n.isRead
                                      ? AppColors.surfaceVariant
                                      : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Icon(
                                  _iconForType(n.type),
                                  size: 20,
                                  color: n.isRead ? AppColors.textTertiary : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (!n.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      n.createdAt.timeAgo,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
    'order' => Icons.receipt_long_rounded,
    'promo' => Icons.local_offer_rounded,
    'account' => Icons.person_rounded,
    _ => Icons.notifications_rounded,
  };
}
