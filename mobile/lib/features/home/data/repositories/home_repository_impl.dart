import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../product/data/models/category_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/domain/entities/product.dart';
import '../../domain/entities/banner.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/flash_sale.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/banner_model.dart';
import '../models/brand_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final LocalCacheService? _cache;

  HomeRepositoryImpl({
    required HomeRemoteDataSource remote,
    required NetworkInfo networkInfo,
    LocalCacheService? cache,
  })  : _remote = remote,
        _networkInfo = networkInfo,
        _cache = cache;

  @override
  Future<Either<Failure, List<PromoBanner>>> getBanners() async {
    return _fetchWithCache(
      cacheKey: 'home_banners',
      fetch: () => _remote.getBanners(),
      fromCache: (data) => (data as List)
          .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      toCache: (items) => items.map((b) => {'id': b.id, 'title': b.title, 'imageUrl': b.imageUrl, 'actionUrl': b.actionUrl}).toList(),
      errorLabel: 'banners',
    );
  }

  @override
  Future<Either<Failure, FlashSale?>> getActiveFlashSale() async {
    if (!await _networkInfo.isConnected) return const Right(null);
    try {
      return Right(await _remote.getActiveFlashSale());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load flash sale: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getBestSellers() async {
    return _fetchWithCache(
      cacheKey: 'home_best_sellers',
      fetch: () => _remote.getBestSellers(),
      fromCache: (data) => (data as List)
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      toCache: (items) => items.map((p) => {
        'id': p.id, 'name': p.name, 'description': p.description,
        'price': p.price, 'categoryId': p.categoryId,
        'stock': p.stockQuantity, 'images': <String>[],
        'avgRating': p.averageRating, 'reviewCount': p.reviewCount,
      }).toList(),
      errorLabel: 'products',
    );
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    return _fetchWithCache(
      cacheKey: 'home_categories',
      fetch: () => _remote.getCategories(),
      fromCache: (data) => (data as List)
          .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      toCache: (items) => items.map((c) => {'id': c.id, 'name': c.name, 'imageUrl': c.imageUrl}).toList(),
      errorLabel: 'categories',
    );
  }

  @override
  Future<Either<Failure, List<Brand>>> getBrands() async {
    return _fetchWithCache(
      cacheKey: 'home_brands',
      fetch: () => _remote.getBrands(),
      fromCache: (data) => (data as List)
          .map((e) => BrandModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      toCache: (items) => items.map((b) => {'id': b.id, 'name': b.name, 'slug': b.slug, 'logoUrl': b.logoUrl}).toList(),
      errorLabel: 'brands',
    );
  }

  Future<Either<Failure, List<T>>> _fetchWithCache<T>({
    required String cacheKey,
    required Future<List<T>> Function() fetch,
    required List<T> Function(dynamic) fromCache,
    required dynamic Function(List<T>) toCache,
    required String errorLabel,
  }) async {
    if (!await _networkInfo.isConnected) {
      final cached = _cache?.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        try {
          return Right(fromCache(cached));
        } catch (_) {}
      }
      return const Left(NetworkFailure());
    }
    try {
      final result = await fetch();
      _cache?.put(cacheKey, toCache(result));
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load $errorLabel: $e'));
    }
  }
}
