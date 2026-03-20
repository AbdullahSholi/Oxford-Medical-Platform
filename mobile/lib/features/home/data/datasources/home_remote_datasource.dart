import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../product/data/models/category_model.dart';
import '../../../product/data/models/product_model.dart';
import '../models/banner_model.dart';
import '../models/brand_model.dart';
import '../models/flash_sale_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<BannerModel>> getBanners();
  Future<FlashSaleModel?> getActiveFlashSale();
  Future<List<ProductModel>> getBestSellers();
  Future<List<CategoryModel>> getCategories();
  Future<List<BrandModel>> getBrands();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;

  HomeRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<BannerModel>> getBanners() async {
    final response = await _apiClient.get<List<BannerModel>>(
      ApiEndpoints.banners,
      parser: (data) => (data as List)
          .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load banners');
  }

  @override
  Future<FlashSaleModel?> getActiveFlashSale() async {
    final response = await _apiClient.get<FlashSaleModel?>(
      ApiEndpoints.activeFlashSale,
      parser: (data) => data != null
          ? FlashSaleModel.fromJson(data as Map<String, dynamic>)
          : null,
    );
    if (response.success) return response.data;
    throw ServerException(message: response.error?.message ?? 'Failed to load flash sale');
  }

  @override
  Future<List<ProductModel>> getBestSellers() async {
    final response = await _apiClient.get<List<ProductModel>>(
      ApiEndpoints.products,
      queryParams: {'sort': 'best_selling', 'limit': '10'},
      parser: (data) => (data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load best sellers');
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get<List<CategoryModel>>(
      ApiEndpoints.categories,
      parser: (data) => (data as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load categories');
  }

  @override
  Future<List<BrandModel>> getBrands() async {
    final response = await _apiClient.get<List<BrandModel>>(
      ApiEndpoints.brands,
      parser: (data) => (data as List)
          .map((e) => BrandModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load brands');
  }
}
