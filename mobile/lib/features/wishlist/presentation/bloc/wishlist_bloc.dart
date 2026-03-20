import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/domain/entities/product.dart';

// Events
abstract class WishlistEvent extends Equatable {
  const WishlistEvent();
  @override
  List<Object?> get props => [];
}

class WishlistFetched extends WishlistEvent { const WishlistFetched(); }
class WishlistItemToggled extends WishlistEvent {
  final String productId;
  const WishlistItemToggled(this.productId);
  @override
  List<Object?> get props => [productId];
}

// States
abstract class WishlistState extends Equatable {
  const WishlistState();
  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}
class WishlistLoading extends WishlistState {}
class WishlistLoaded extends WishlistState {
  final List<Product> products;
  final Set<String> productIds;
  const WishlistLoaded({required this.products, required this.productIds});
  @override
  List<Object?> get props => [products];
}
class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final ApiClient _apiClient;

  WishlistBloc(this._apiClient) : super(WishlistInitial()) {
    on<WishlistFetched>(_onFetched);
    on<WishlistItemToggled>(_onToggled);
  }

  Future<void> _onFetched(WishlistFetched event, Emitter<WishlistState> emit) async {
    emit(WishlistLoading());
    final response = await _apiClient.get<List<Product>>(
      ApiEndpoints.wishlist,
      parser: (data) => (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        final product = map['product'] as Map<String, dynamic>? ?? map;
        return ProductModel.fromJson(product);
      }).toList(),
    );
    if (response.success) {
      final products = response.data!;
      emit(WishlistLoaded(products: products, productIds: products.map((p) => p.id).toSet()));
    } else {
      emit(WishlistError(response.error?.message ?? 'Failed to load wishlist'));
    }
  }

  Future<void> _onToggled(WishlistItemToggled event, Emitter<WishlistState> emit) async {
    final current = state;
    if (current is WishlistLoaded && current.productIds.contains(event.productId)) {
      await _apiClient.delete<void>(ApiEndpoints.wishlistItem(event.productId), parser: (_) {});
    } else {
      await _apiClient.post<void>(ApiEndpoints.wishlistItem(event.productId), parser: (_) {});
    }
    add(const WishlistFetched());
  }
}
