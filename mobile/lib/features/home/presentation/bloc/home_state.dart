import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/domain/entities/product.dart';
import '../../domain/entities/banner.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/flash_sale.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<PromoBanner> banners;
  final FlashSale? flashSale;
  final List<Product> bestSellers;
  final List<Category> categories;
  final List<Brand> brands;

  const HomeLoaded({
    required this.banners,
    this.flashSale,
    required this.bestSellers,
    required this.categories,
    this.brands = const [],
  });

  @override
  List<Object?> get props => [banners, flashSale, bestSellers, categories, brands];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
