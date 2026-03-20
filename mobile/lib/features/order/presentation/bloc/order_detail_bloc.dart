import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

abstract class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();
  @override
  List<Object?> get props => [];
}

class OrderDetailFetched extends OrderDetailEvent {
  final String id;
  const OrderDetailFetched(this.id);
  @override
  List<Object?> get props => [id];
}

class OrderCancelRequested extends OrderDetailEvent {
  final String id;
  const OrderCancelRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class OrderStatusUpdated extends OrderDetailEvent {
  final String orderId;
  final String status;
  const OrderStatusUpdated({required this.orderId, required this.status});
  @override
  List<Object?> get props => [orderId, status];
}

abstract class OrderDetailState extends Equatable {
  const OrderDetailState();
  @override
  List<Object?> get props => [];
}

class OrderDetailInitial extends OrderDetailState {}
class OrderDetailLoading extends OrderDetailState {}
class OrderDetailLoaded extends OrderDetailState {
  final Order order;
  const OrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}
class OrderDetailError extends OrderDetailState {
  final String message;
  const OrderDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  final OrderRepository _repository;

  OrderDetailBloc(this._repository) : super(OrderDetailInitial()) {
    on<OrderDetailFetched>(_onFetched);
    on<OrderCancelRequested>(_onCancel);
    on<OrderStatusUpdated>(_onStatusUpdated);
  }

  Future<void> _onFetched(OrderDetailFetched event, Emitter<OrderDetailState> emit) async {
    emit(OrderDetailLoading());
    final result = await _repository.getOrderById(event.id);
    result.fold((f) => emit(OrderDetailError(f.message)), (order) => emit(OrderDetailLoaded(order)));
  }

  Future<void> _onCancel(OrderCancelRequested event, Emitter<OrderDetailState> emit) async {
    emit(OrderDetailLoading());
    final result = await _repository.cancelOrder(event.id);
    result.fold((f) => emit(OrderDetailError(f.message)), (order) => emit(OrderDetailLoaded(order)));
  }

  Future<void> _onStatusUpdated(OrderStatusUpdated event, Emitter<OrderDetailState> emit) async {
    // Re-fetch the order to get full updated data
    final result = await _repository.getOrderById(event.orderId);
    result.fold((_) {}, (order) => emit(OrderDetailLoaded(order)));
  }
}
