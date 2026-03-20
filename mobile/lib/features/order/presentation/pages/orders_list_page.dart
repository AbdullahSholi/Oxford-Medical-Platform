import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_list_bloc.dart';
import '../widgets/order_card.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderListBloc>().add(const OrderListFetched());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.ordersTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Delivered'),
              Tab(text: 'Cancelled'),
            ],
            onTap: (index) {
              switch (index) {
                case 1:
                  // Active = all non-terminal statuses
                  context.read<OrderListBloc>().add(const OrderListFetched(activeOnly: true));
                case 2:
                  context.read<OrderListBloc>().add(const OrderListFetched(status: OrderStatus.delivered));
                case 3:
                  context.read<OrderListBloc>().add(const OrderListFetched(status: OrderStatus.cancelled));
                default:
                  context.read<OrderListBloc>().add(const OrderListFetched());
              }
            },
          ),
        ),
        body: BlocBuilder<OrderListBloc, OrderListState>(
          builder: (context, state) {
            if (state is OrderListLoading) return const AppLoading();
            if (state is OrderListError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: () => context.read<OrderListBloc>().add(const OrderListFetched()),
              );
            }
            if (state is OrderListLoaded) {
              if (state.orders.isEmpty) {
                return AppEmptyState(
                  title: context.l10n.ordersEmpty,
                  icon: Icons.receipt_long_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.orders.length,
                separatorBuilder: (_, __) => AppSpacing.verticalGapMd,
                itemBuilder: (_, index) => OrderCard(order: state.orders[index]),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
