import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_response.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<Either<Failure, PaginatedResponse<Order>>> getOrders({int page = 1, OrderStatus? status});
  Future<Either<Failure, Order>> getOrderById(String id);
  Future<Either<Failure, Order>> checkout({required String addressId, String? paymentMethod, String? discountCode, String? notes});
  Future<Either<Failure, Order>> cancelOrder(String id);
}
