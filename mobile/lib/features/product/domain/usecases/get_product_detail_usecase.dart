import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductDetailUseCase extends UseCase<Product, String> {
  final ProductRepository _repository;

  GetProductDetailUseCase(this._repository);

  @override
  Future<Either<Failure, Product>> call(String id) {
    return _repository.getProductById(id);
  }
}
