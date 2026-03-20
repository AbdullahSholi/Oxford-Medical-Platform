import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/domain/entities/product.dart';
import '../entities/banner.dart';
import '../entities/brand.dart';
import '../entities/flash_sale.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<PromoBanner>>> getBanners();
  Future<Either<Failure, FlashSale?>> getActiveFlashSale();
  Future<Either<Failure, List<Product>>> getBestSellers();
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, List<Brand>>> getBrands();
}
