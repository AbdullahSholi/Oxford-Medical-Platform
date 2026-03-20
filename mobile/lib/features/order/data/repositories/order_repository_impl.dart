import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  OrderRepositoryImpl({required OrderRemoteDataSource remote, required NetworkInfo networkInfo})
      : _remote = remote, _networkInfo = networkInfo;

  @override
  Future<Either<Failure, PaginatedResponse<Order>>> getOrders({int page = 1, OrderStatus? status}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.getOrders(page: page, status: status)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String id) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.getOrderById(id)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Order>> checkout({required String addressId, String? paymentMethod, String? discountCode, String? notes}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.checkout(addressId: addressId, paymentMethod: paymentMethod, discountCode: discountCode, notes: notes)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Order>> cancelOrder(String id) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.cancelOrder(id)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }
}
