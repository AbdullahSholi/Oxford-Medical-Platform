import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final double? discountPercentage;
  final String imageUrl;
  final List<String> images;
  final String categoryId;
  final String? categoryName;
  final bool inStock;
  final int stockQuantity;
  final String? manufacturer;
  final String? activeIngredient;
  final String? dosageForm;
  final String? strength;
  final String? packSize;
  final double averageRating;
  final int reviewCount;
  final List<BulkPricing>? bulkPricing;
  final bool requiresPrescription;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discountPercentage,
    required this.imageUrl,
    this.images = const [],
    required this.categoryId,
    this.categoryName,
    required this.inStock,
    required this.stockQuantity,
    this.manufacturer,
    this.activeIngredient,
    this.dosageForm,
    this.strength,
    this.packSize,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.bulkPricing,
    this.requiresPrescription = false,
  });

  @override
  List<Object?> get props => [id];
}

class BulkPricing extends Equatable {
  final int minQuantity;
  final int maxQuantity;
  final double pricePerUnit;

  const BulkPricing({
    required this.minQuantity,
    required this.maxQuantity,
    required this.pricePerUnit,
  });

  @override
  List<Object?> get props => [minQuantity, maxQuantity, pricePerUnit];
}

class ProductFilter extends Equatable {
  final String? categoryId;
  final String? brandId;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStockOnly;
  final String? manufacturer;
  final String? dosageForm;

  const ProductFilter({
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly,
    this.manufacturer,
    this.dosageForm,
  });

  factory ProductFilter.empty() => const ProductFilter();

  bool get isActive =>
      categoryId != null ||
      brandId != null ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly != null ||
      manufacturer != null ||
      dosageForm != null;

  ProductFilter copyWith({
    String? Function()? categoryId,
    String? Function()? brandId,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    bool? Function()? inStockOnly,
    String? Function()? manufacturer,
    String? Function()? dosageForm,
  }) {
    return ProductFilter(
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      brandId: brandId != null ? brandId() : this.brandId,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      inStockOnly: inStockOnly != null ? inStockOnly() : this.inStockOnly,
      manufacturer: manufacturer != null ? manufacturer() : this.manufacturer,
      dosageForm: dosageForm != null ? dosageForm() : this.dosageForm,
    );
  }

  @override
  List<Object?> get props => [categoryId, brandId, minPrice, maxPrice, inStockOnly, manufacturer, dosageForm];
}

enum SortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  newest,
  rating,
  bestSelling,
}
