import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/domain/entities/product.dart';
import '../entities/banner.dart';
import '../entities/brand.dart';
import '../entities/flash_sale.dart';
import '../repositories/home_repository.dart';

class GetHomeDataUseCase extends UseCase<HomeData, NoParams> {
  final HomeRepository _repository;

  GetHomeDataUseCase(this._repository);

  @override
  Future<Either<Failure, HomeData>> call(NoParams params) async {
    // Sequential calls to avoid Dio concurrency issues on web
    final banners = await _repository.getBanners();
    final flashSale = await _repository.getActiveFlashSale();
    final bestSellers = await _repository.getBestSellers();
    final categories = await _repository.getCategories();
    final brands = await _repository.getBrands();

    // Return data even if some calls fail
    return Right(HomeData(
      banners: banners.getOrElse(() => []),
      flashSale: flashSale.getOrElse(() => null),
      bestSellers: bestSellers.getOrElse(() => []),
      categories: categories.getOrElse(() => []),
      brands: brands.getOrElse(() => []),
    ));
  }
}

class HomeData {
  final List<PromoBanner> banners;
  final FlashSale? flashSale;
  final List<Product> bestSellers;
  final List<Category> categories;
  final List<Brand> brands;

  const HomeData({
    required this.banners,
    this.flashSale,
    required this.bestSellers,
    required this.categories,
    this.brands = const [],
  });
}
