import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase
    extends UseCase<PaginatedResponse<Product>, GetProductsParams> {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  @override
  Future<Either<Failure, PaginatedResponse<Product>>> call(
    GetProductsParams params,
  ) {
    return _repository.getProducts(
      filter: params.filter,
      sort: params.sort,
      page: params.page,
    );
  }
}

class GetProductsParams {
  final ProductFilter? filter;
  final SortOption? sort;
  final int page;

  const GetProductsParams({this.filter, this.sort, this.page = 1});
}
