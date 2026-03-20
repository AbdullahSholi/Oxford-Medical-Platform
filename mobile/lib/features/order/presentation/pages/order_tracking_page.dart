import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_detail_bloc.dart';

class OrderTrackingPage extends StatefulWidget {
  final String id;
  const OrderTrackingPage({super.key, required this.id});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late final SocketService _socketService;
  StreamSubscription<Map<String, dynamic>>? _orderSub;

  @override
  void initState() {
    super.initState();
    _socketService = di.sl<SocketService>();
    _socketService.trackOrder(widget.id);

    _orderSub = _socketService.onOrderUpdate.listen((data) {
      final orderId = data['orderId'] as String?;
      final status = data['status'] as String?;
      if (orderId == widget.id && status != null) {
        context.read<OrderDetailBloc>().add(
          OrderStatusUpdated(orderId: orderId!, status: status),
        );
      }
    });

    context.read<OrderDetailBloc>().add(OrderDetailFetched(widget.id));
  }

  @override
  void dispose() {
    _socketService.untrackOrder(widget.id);
    _orderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.orderTracking,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          if (state is OrderDetailLoading) return const AppLoading();
          if (state is OrderDetailError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<OrderDetailBloc>().add(OrderDetailFetched(widget.id)),
            );
          }
          if (state is OrderDetailLoaded) {
            return _TrackingContent(order: state.order);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TrackingContent extends StatelessWidget {
  final Order order;
  const _TrackingContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _trackingSteps;
    final currentIndex = _currentStepIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppSpacing.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(_statusIcon, size: 28, color: _statusColor),
                ),
                AppSpacing.horizontalGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusSubtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalGapLg,

          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: order.status == OrderStatus.cancelled
                  ? AppColors.errorLight
                  : AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: order.status == OrderStatus.cancelled ? AppColors.error : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  order.status == OrderStatus.cancelled ? 'Cancelled' : 'Live Tracking',
                  style: TextStyle(
                    color: order.status == OrderStatus.cancelled ? AppColors.error : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalGapLg,

          // Timeline card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppSpacing.shadowSm,
            ),
            child: Column(
              children: List.generate(steps.length, (index) {
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;
                final isLast = index == steps.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 36,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted ? AppColors.primary : AppColors.surfaceVariant,
                                border: isCurrent
                                    ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 3)
                                    : null,
                                boxShadow: isCurrent
                                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)]
                                    : null,
                              ),
                              child: Icon(
                                isCompleted && !isCurrent ? Icons.check_rounded : _stepIcon(index),
                                size: 16,
                                color: isCompleted ? Colors.white : AppColors.textHint,
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCompleted && index < currentIndex
                                        ? AppColors.primary
                                        : AppColors.divider,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  steps[index]['title']!,
                                  style: TextStyle(
                                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                                    fontSize: 14,
                                    color: isCompleted ? AppColors.textPrimary : AppColors.textHint,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                steps[index]['description']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCompleted ? AppColors.textSecondary : AppColors.textHint,
                                ),
                              ),
                              if (isCurrent)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          AppSpacing.verticalGapLg,

          // Order number
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Order #${order.orderNumber.length > 8 ? order.orderNumber.substring(0, 8).toUpperCase() : order.orderNumber}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _stepIcon(int index) => switch (index) {
    0 => Icons.receipt_long_rounded,
    1 => Icons.check_circle_rounded,
    2 => Icons.settings_rounded,
    3 => Icons.local_shipping_rounded,
    4 => Icons.done_all_rounded,
    _ => Icons.circle,
  };

  List<Map<String, String>> get _trackingSteps => [
    {'title': 'Order Placed', 'description': 'Your order has been received'},
    {'title': 'Confirmed', 'description': 'Order confirmed by the pharmacy'},
    {'title': 'Processing', 'description': 'Your order is being prepared'},
    {'title': 'Shipped', 'description': 'Order has been dispatched'},
    {'title': 'Delivered', 'description': 'Order delivered successfully'},
  ];

  int get _currentStepIndex => switch (order.status) {
    OrderStatus.pending => 0,
    OrderStatus.confirmed => 1,
    OrderStatus.processing => 2,
    OrderStatus.shipped => 3,
    OrderStatus.delivered => 4,
    OrderStatus.cancelled => -1,
  };

  IconData get _statusIcon => switch (order.status) {
    OrderStatus.pending => Icons.hourglass_top_rounded,
    OrderStatus.confirmed => Icons.check_circle_outline_rounded,
    OrderStatus.processing => Icons.inventory_2_outlined,
    OrderStatus.shipped => Icons.local_shipping_rounded,
    OrderStatus.delivered => Icons.check_circle_rounded,
    OrderStatus.cancelled => Icons.cancel_outlined,
  };

  Color get _statusColor => switch (order.status) {
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.error,
    _ => AppColors.primary,
  };

  String get _statusTitle => switch (order.status) {
    OrderStatus.pending => 'Order Placed',
    OrderStatus.confirmed => 'Order Confirmed',
    OrderStatus.processing => 'Being Prepared',
    OrderStatus.shipped => 'On the Way',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };

  String get _statusSubtitle => switch (order.status) {
    OrderStatus.pending => 'Waiting for confirmation',
    OrderStatus.confirmed => 'Your order is confirmed',
    OrderStatus.processing => 'Pharmacy is preparing your items',
    OrderStatus.shipped => 'Estimated delivery: 30-45 minutes',
    OrderStatus.delivered => 'Your order has been delivered',
    OrderStatus.cancelled => 'This order was cancelled',
  };
}
