import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  CartRepositoryImpl({required CartRemoteDataSource remote, required NetworkInfo networkInfo})
      : _remote = remote, _networkInfo = networkInfo;

  @override
  Future<Either<Failure, Cart>> getCart() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.getCart()); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Cart>> addItem({required String productId, int quantity = 1}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.addItem(productId: productId, quantity: quantity)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Cart>> updateQuantity({required String itemId, required int quantity}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.updateQuantity(itemId: itemId, quantity: quantity)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Cart>> removeItem(String itemId) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.removeItem(itemId)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Cart>> applyCoupon(String code) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.applyCoupon(code)); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, Cart>> removeCoupon() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await _remote.removeCoupon()); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }

  @override
  Future<Either<Failure, void>> clearCart() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try { await _remote.clearCart(); return const Right(null); }
    on ServerException catch (e) { return Left(ServerFailure(message: e.message)); }
  }
}
