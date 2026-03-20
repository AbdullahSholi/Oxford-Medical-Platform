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
        title: Text(context.l10n.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationBloc>().add(const NotificationsAllMarkedRead()),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) return const AppLoading();
          if (state is NotificationError) {
            return AppErrorWidget(message: state.message, onRetry: () => context.read<NotificationBloc>().add(const NotificationsFetched()));
          }
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return AppEmptyState(title: context.l10n.notificationsEmpty, icon: Icons.notifications_off_outlined);
            }
            return ListView.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final n = state.notifications[index];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    color: AppColors.error,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    context.read<NotificationBloc>().add(NotificationDeleted(n.id));
                    context.showSnackBar('Notification deleted');
                  },
                  child: ListTile(
                  tileColor: n.isRead ? null : AppColors.primaryLight.withOpacity(0.05),
                  leading: CircleAvatar(
                    backgroundColor: n.isRead ? AppColors.surfaceVariant : AppColors.primaryLight.withOpacity(0.2),
                    child: Icon(_iconForType(n.type), size: 20, color: n.isRead ? AppColors.textHint : AppColors.primary),
                  ),
                  title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, fontSize: 14)),
                  subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  trailing: Text(n.createdAt.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  onTap: () {
                    if (!n.isRead) context.read<NotificationBloc>().add(NotificationMarkedRead(n.id));
                    final orderId = n.data?['orderId'] as String?;
                    if (orderId != null) context.push('/orders/$orderId');
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
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
