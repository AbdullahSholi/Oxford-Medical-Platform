import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/socket_service.dart';
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
      appBar: AppBar(title: Text(context.l10n.orderTracking)),
      body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          if (state is OrderDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrderDetailError) {
            return Center(child: Text(state.message));
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 40, color: _statusColor),
                AppSpacing.horizontalGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_statusTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_statusSubtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalGapXl,

          // Live indicator
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: order.status == OrderStatus.cancelled ? AppColors.error : AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              AppSpacing.horizontalGapSm,
              Text(
                order.status == OrderStatus.cancelled ? 'Cancelled' : 'Live Tracking',
                style: TextStyle(
                  color: order.status == OrderStatus.cancelled ? AppColors.error : AppColors.success,
                  fontSize: 12, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapLg,

          // Timeline
          ...List.generate(steps.length, (index) {
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot + line
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: isCurrent ? 20 : 14,
                          height: isCurrent ? 20 : 14,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.primary : AppColors.divider,
                            shape: BoxShape.circle,
                            border: isCurrent ? Border.all(color: AppColors.primary, width: 3) : null,
                          ),
                          child: isCompleted && !isCurrent
                              ? const Icon(Icons.check, size: 10, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isCompleted && index < currentIndex ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.horizontalGapMd,
                  // Step content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[index]['title']!,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCompleted ? AppColors.textPrimary : AppColors.textHint,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          AppSpacing.verticalGapXl,

          // Order info
          Text('Order #${order.orderNumber.length > 8 ? order.orderNumber.substring(0, 8).toUpperCase() : order.orderNumber}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

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
