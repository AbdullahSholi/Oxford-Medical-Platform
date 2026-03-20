import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/cart_model.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getCart();
  Future<CartModel> addItem({required String productId, int quantity = 1});
  Future<CartModel> updateQuantity({required String itemId, required int quantity});
  Future<CartModel> removeItem(String itemId);
  Future<CartModel> applyCoupon(String code);
  Future<CartModel> removeCoupon();
  Future<void> clearCart();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final ApiClient _apiClient;
  CartRemoteDataSourceImpl(this._apiClient);

  @override
  Future<CartModel> getCart() async {
    final response = await _apiClient.get<CartModel>(
      ApiEndpoints.cart,
      parser: (data) => CartModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load cart');
  }

  @override
  Future<CartModel> addItem({required String productId, int quantity = 1}) async {
    final response = await _apiClient.post<CartModel>(
      ApiEndpoints.cartItems,
      data: {'productId': productId, 'quantity': quantity},
      parser: (data) => CartModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to add item');
  }

  @override
  Future<CartModel> updateQuantity({required String itemId, required int quantity}) async {
    final response = await _apiClient.patch<CartModel>(
      ApiEndpoints.cartItem(itemId),
      data: {'quantity': quantity},
      parser: (data) => CartModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to update quantity');
  }

  @override
  Future<CartModel> removeItem(String itemId) async {
    final response = await _apiClient.delete<CartModel>(
      ApiEndpoints.cartItem(itemId),
      parser: (data) => CartModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to remove item');
  }

  @override
  Future<CartModel> applyCoupon(String code) async {
    final response = await _apiClient.post<CartModel>(
      ApiEndpoints.cartApplyCoupon,
      data: {'code': code},
      parser: (data) => CartModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Invalid coupon code');
  }

  @override
  Future<CartModel> removeCoupon() async {
    final response = await _apiClient.delete<CartModel>(
      ApiEndpoints.cartRemoveCoupon,
      parser: (data) => CartModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to remove coupon');
  }

  @override
  Future<void> clearCart() async {
    final response = await _apiClient.delete<void>(
      ApiEndpoints.cart,
      parser: (_) {},
    );
    if (!response.success) {
      throw ServerException(message: response.error?.message ?? 'Failed to clear cart');
    }
  }
}
