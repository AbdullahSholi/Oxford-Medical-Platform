import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/product.dart';
import '../../../review/data/models/review_model.dart';
import '../../../review/domain/entities/review.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<PaginatedResponse<Product>> getProducts({
    ProductFilter? filter,
    SortOption? sort,
    int page = 1,
  });
  Future<ProductModel> getProductById(String id);
  Future<PaginatedResponse<Product>> searchProducts({
    required String query,
    int page = 1,
  });
  Future<List<Review>> getProductReviews(String productId);
  Future<void> createReview({
    required String productId,
    required int rating,
    String? title,
    String? body,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl(this._apiClient);

  @override
  Future<PaginatedResponse<Product>> getProducts({
    ProductFilter? filter,
    SortOption? sort,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': AppConstants.defaultPageSize.toString(),
    };
    if (filter?.categoryId != null) queryParams['categoryId'] = filter!.categoryId;
    if (filter?.brandId != null) queryParams['brandId'] = filter!.brandId;
    if (filter?.minPrice != null) queryParams['minPrice'] = filter!.minPrice.toString();
    if (filter?.maxPrice != null) queryParams['maxPrice'] = filter!.maxPrice.toString();
    if (filter?.inStockOnly == true) queryParams['inStock'] = 'true';
    if (filter?.manufacturer != null) queryParams['manufacturer'] = filter!.manufacturer;
    if (sort != null) queryParams['sort'] = _sortToApi(sort);

    final response = await _apiClient.get<PaginatedResponse<Product>>(
      ApiEndpoints.products,
      queryParams: queryParams,
      parser: (data) => _parsePaginatedProducts(data),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load products');
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final response = await _apiClient.get<ProductModel>(
      ApiEndpoints.productById(id),
      parser: (data) => ProductModel.fromJson(data as Map<String, dynamic>),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Product not found');
  }

  @override
  Future<PaginatedResponse<Product>> searchProducts({
    required String query,
    int page = 1,
  }) async {
    final response = await _apiClient.get<PaginatedResponse<Product>>(
      ApiEndpoints.productSearch,
      queryParams: {
        'search': query,
        'page': page.toString(),
        'limit': AppConstants.defaultPageSize.toString(),
      },
      parser: (data) => _parsePaginatedProducts(data),
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Search failed');
  }

  @override
  Future<List<Review>> getProductReviews(String productId) async {
    final response = await _apiClient.get<List<Review>>(
      ApiEndpoints.productReviews(productId),
      parser: (data) {
        if (data is List) {
          return data
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <Review>[];
      },
    );
    if (response.success) return response.data!;
    throw ServerException(message: response.error?.message ?? 'Failed to load reviews');
  }

  @override
  Future<void> createReview({
    required String productId,
    required int rating,
    String? title,
    String? body,
  }) async {
    final response = await _apiClient.post<void>(
      ApiEndpoints.reviews,
      data: {
        'productId': productId,
        'rating': rating,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      },
      parser: (_) {},
    );
    if (!response.success) {
      throw ServerException(
        message: response.error?.message ?? 'Failed to submit review',
        statusCode: response.error?.statusCode,
      );
    }
  }

  String _sortToApi(SortOption sort) => switch (sort) {
    SortOption.priceAsc => 'price_asc',
    SortOption.priceDesc => 'price_desc',
    SortOption.newest => 'newest',
    SortOption.rating => 'rating',
    SortOption.bestSelling => 'best_selling',
    _ => 'newest',
  };

  PaginatedResponse<Product> _parsePaginatedProducts(dynamic data) {
    // Backend may return a flat array or a paginated object
    if (data is List) {
      final items = data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResponse<Product>(
        items: items,
        total: items.length,
        page: 1,
        pageSize: items.length,
        hasMore: false,
      );
    }
    final map = data as Map<String, dynamic>;
    final rawItems = map['items'] ?? map['products'] ?? map['data'] ?? [];
    return PaginatedResponse<Product>(
      items: (rawItems as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int? ?? 0,
      page: map['page'] as int? ?? 1,
      pageSize: map['pageSize'] as int? ?? AppConstants.defaultPageSize,
      hasMore: map['hasMore'] as bool? ?? false,
    );
  }
}
