import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';

// Events
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartLoaded extends CartEvent { const CartLoaded(); }
class CartItemAdded extends CartEvent {
  final String productId;
  final int quantity;
  const CartItemAdded({required this.productId, this.quantity = 1});
  @override
  List<Object?> get props => [productId, quantity];
}
class CartItemQuantityUpdated extends CartEvent {
  final String itemId;
  final int quantity;
  const CartItemQuantityUpdated({required this.itemId, required this.quantity});
  @override
  List<Object?> get props => [itemId, quantity];
}
class CartItemRemoved extends CartEvent {
  final String itemId;
  const CartItemRemoved(this.itemId);
  @override
  List<Object?> get props => [itemId];
}
class CartCouponApplied extends CartEvent {
  final String code;
  const CartCouponApplied(this.code);
  @override
  List<Object?> get props => [code];
}
class CartCouponRemoved extends CartEvent { const CartCouponRemoved(); }

// States
abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}
class CartLoadingState extends CartState {}
class CartLoadedState extends CartState {
  final Cart cart;
  const CartLoadedState(this.cart);
  @override
  List<Object?> get props => [cart];
}
class CartErrorState extends CartState {
  final String message;
  const CartErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _repository;

  CartBloc(this._repository) : super(CartInitial()) {
    on<CartLoaded>(_onLoaded);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemQuantityUpdated>(_onQuantityUpdated);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCouponRemoved>(_onCouponRemoved);
  }

  Future<void> _onLoaded(CartLoaded event, Emitter<CartState> emit) async {
    emit(CartLoadingState());
    final result = await _repository.getCart();
    result.fold(
      (f) => emit(CartErrorState(f.message)),
      (cart) => emit(CartLoadedState(cart)),
    );
  }

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    final result = await _repository.addItem(productId: event.productId, quantity: event.quantity);
    result.fold(
      (f) => emit(CartErrorState(f.message)),
      (cart) => emit(CartLoadedState(cart)),
    );
  }

  Future<void> _onQuantityUpdated(CartItemQuantityUpdated event, Emitter<CartState> emit) async {
    final result = await _repository.updateQuantity(itemId: event.itemId, quantity: event.quantity);
    result.fold(
      (f) => emit(CartErrorState(f.message)),
      (cart) => emit(CartLoadedState(cart)),
    );
  }

  Future<void> _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    final result = await _repository.removeItem(event.itemId);
    result.fold(
      (f) => emit(CartErrorState(f.message)),
      (cart) => emit(CartLoadedState(cart)),
    );
  }

  Future<void> _onCouponApplied(CartCouponApplied event, Emitter<CartState> emit) async {
    final result = await _repository.applyCoupon(event.code);
    result.fold(
      (f) => emit(CartErrorState(f.message)),
      (cart) => emit(CartLoadedState(cart)),
    );
  }

  Future<void> _onCouponRemoved(CartCouponRemoved event, Emitter<CartState> emit) async {
    final result = await _repository.removeCoupon();
    result.fold(
      (f) => emit(CartErrorState(f.message)),
      (cart) => emit(CartLoadedState(cart)),
    );
  }
}
