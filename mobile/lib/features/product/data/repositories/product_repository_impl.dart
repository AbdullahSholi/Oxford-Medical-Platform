import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  ProductRepositoryImpl({
    required ProductRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, PaginatedResponse<Product>>> getProducts({
    ProductFilter? filter,
    SortOption? sort,
    int page = 1,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getProducts(filter: filter, sort: sort, page: page));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getProductById(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Product>>> searchProducts({
    required String query,
    int page = 1,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.searchProducts(query: query, page: page));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
