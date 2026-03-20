import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class SearchProductsUseCase
    extends UseCase<PaginatedResponse<Product>, SearchProductsParams> {
  final ProductRepository _repository;

  SearchProductsUseCase(this._repository);

  @override
  Future<Either<Failure, PaginatedResponse<Product>>> call(
    SearchProductsParams params,
  ) {
    return _repository.searchProducts(query: params.query, page: params.page);
  }
}

class SearchProductsParams {
  final String query;
  final int page;

  const SearchProductsParams({required this.query, this.page = 1});
}
