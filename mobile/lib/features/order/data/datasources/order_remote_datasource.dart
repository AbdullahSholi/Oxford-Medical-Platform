import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/order.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<PaginatedResponse<Order>> getOrders({int page = 1, OrderStatus? status});
  Future<OrderModel> getOrderById(String id);
  Future<OrderModel> checkout({required String addressId, String? paymentMethod, String? discountCode, String? notes});
  Future<OrderModel> cancelOrder(String id);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient _apiClient;
  OrderRemoteDataSourceImpl(this._apiClient);

  @override
  Future<PaginatedResponse<Order>> getOrders({int page = 1, OrderStatus? status}) async {
    final params = <String, dynamic>{'page': page.toString(), 'limit': AppConstants.defaultPageSize.toString()};
    if (status != null) params['status'] = status.name;
    final response = await _apiClient.get<PaginatedResponse<Order>>(
      ApiEndpoints.orders,
      queryParams: params,
      parser: (data) => _parsePaginatedOrders(data),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load orders');
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    final response = await _apiClient.get<OrderModel>(
      ApiEndpoints.orderById(id),
      parser: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Order not found');
  }

  @override
  Future<OrderModel> checkout({required String addressId, String? paymentMethod, String? discountCode, String? notes}) async {
    final response = await _apiClient.post<OrderModel>(
      ApiEndpoints.checkout,
      data: {'addressId': addressId, if (paymentMethod != null) 'paymentMethod': paymentMethod, if (discountCode != null) 'discountCode': discountCode, if (notes != null) 'notes': notes},
      parser: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Checkout failed');
  }

  @override
  Future<OrderModel> cancelOrder(String id) async {
    final response = await _apiClient.post<OrderModel>(
      ApiEndpoints.orderCancel(id),
      parser: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to cancel order');
  }

  PaginatedResponse<Order> _parsePaginatedOrders(dynamic data) {
    if (data is List) {
      final items = data
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResponse<Order>(
        items: items,
        total: items.length,
        page: 1,
        pageSize: items.length,
        hasMore: false,
      );
    }
    final map = data as Map<String, dynamic>;
    final rawItems = map['items'] ?? map['orders'] ?? map['data'] ?? [];
    return PaginatedResponse<Order>(
      items: (rawItems as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int? ?? 0,
      page: map['page'] as int? ?? 1,
      pageSize: map['pageSize'] as int? ?? AppConstants.defaultPageSize,
      hasMore: map['hasMore'] as bool? ?? false,
    );
  }
}
