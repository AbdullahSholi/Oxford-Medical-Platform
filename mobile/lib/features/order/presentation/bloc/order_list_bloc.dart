import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

// Events
abstract class OrderListEvent extends Equatable {
  const OrderListEvent();
  @override
  List<Object?> get props => [];
}

class OrderListFetched extends OrderListEvent {
  final OrderStatus? status;
  final bool activeOnly;
  const OrderListFetched({this.status, this.activeOnly = false});
  @override
  List<Object?> get props => [status, activeOnly];
}

class OrderListNextPageFetched extends OrderListEvent {
  const OrderListNextPageFetched();
}

// States
abstract class OrderListState extends Equatable {
  const OrderListState();
  @override
  List<Object?> get props => [];
}

class OrderListInitial extends OrderListState {}
class OrderListLoading extends OrderListState {}

class OrderListLoaded extends OrderListState {
  final List<Order> orders;
  final bool hasReachedMax;
  final int currentPage;
  const OrderListLoaded({required this.orders, required this.hasReachedMax, required this.currentPage});
  @override
  List<Object?> get props => [orders, hasReachedMax, currentPage];
}

class OrderListError extends OrderListState {
  final String message;
  const OrderListError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  final OrderRepository _repository;
  OrderStatus? _statusFilter;
  bool _activeOnly = false;

  static const _activeStatuses = {
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipped,
  };

  OrderListBloc(this._repository) : super(OrderListInitial()) {
    on<OrderListFetched>(_onFetched);
    on<OrderListNextPageFetched>(_onNextPage);
  }

  Future<void> _onFetched(OrderListFetched event, Emitter<OrderListState> emit) async {
    _statusFilter = event.status;
    _activeOnly = event.activeOnly;
    emit(OrderListLoading());
    final result = await _repository.getOrders(status: event.status);
    result.fold(
      (f) => emit(OrderListError(f.message)),
      (data) {
        final items = _activeOnly
            ? data.items.where((o) => _activeStatuses.contains(o.status)).toList()
            : data.items;
        emit(OrderListLoaded(orders: items, hasReachedMax: !data.hasMore, currentPage: 1));
      },
    );
  }

  Future<void> _onNextPage(OrderListNextPageFetched event, Emitter<OrderListState> emit) async {
    final currentState = state;
    if (currentState is! OrderListLoaded || currentState.hasReachedMax) return;
    final nextPage = currentState.currentPage + 1;
    final result = await _repository.getOrders(page: nextPage, status: _statusFilter);
    result.fold(
      (f) => emit(OrderListError(f.message)),
      (data) => emit(OrderListLoaded(
        orders: [...currentState.orders, ...data.items],
        hasReachedMax: !data.hasMore,
        currentPage: nextPage,
      )),
    );
  }
}
