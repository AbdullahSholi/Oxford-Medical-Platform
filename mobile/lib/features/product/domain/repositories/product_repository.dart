import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_response.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, PaginatedResponse<Product>>> getProducts({
    ProductFilter? filter,
    SortOption? sort,
    int page = 1,
  });

  Future<Either<Failure, Product>> getProductById(String id);

  Future<Either<Failure, PaginatedResponse<Product>>> searchProducts({
    required String query,
    int page = 1,
  });
}
