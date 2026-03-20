import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.originalPrice,
    super.discountPercentage,
    required super.imageUrl,
    super.images,
    required super.categoryId,
    super.categoryName,
    required super.inStock,
    required super.stockQuantity,
    super.manufacturer,
    super.activeIngredient,
    super.dosageForm,
    super.strength,
    super.packSize,
    super.averageRating,
    super.reviewCount,
    super.bulkPricing,
    super.requiresPrescription,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Backend returns Decimal fields as strings; parse safely
    double _toDouble(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    double? _toDoubleOrNull(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int _toInt(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);

    // Images may be list of strings or list of objects with 'url' field
    final rawImages = json['images'] as List<dynamic>? ?? [];
    final imageList = rawImages.map((e) {
      if (e is String) return e;
      if (e is Map) return (e['url'] ?? e['imageUrl'] ?? '') as String;
      return '';
    }).where((s) => s.isNotEmpty).toList();

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: _toDouble(json['price']),
      originalPrice: _toDoubleOrNull(json['originalPrice'] ?? json['salePrice']),
      discountPercentage: _toDoubleOrNull(json['discountPercentage']),
      imageUrl: json['imageUrl'] as String? ?? (imageList.isNotEmpty ? imageList.first : ''),
      images: imageList,
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: (json['categoryName'] ?? (json['category'] is Map ? json['category']['name'] : null)) as String?,
      inStock: json['inStock'] as bool? ?? ((json['stock'] ?? 0) is int ? (json['stock'] as int) > 0 : true),
      stockQuantity: _toInt(json['stockQuantity'] ?? json['stock']),
      manufacturer: (json['manufacturer'] ?? (json['brand'] is Map ? json['brand']['name'] : null)) as String?,
      activeIngredient: json['activeIngredient'] as String?,
      dosageForm: json['dosageForm'] as String?,
      strength: json['strength'] as String?,
      packSize: json['packSize'] as String?,
      averageRating: _toDouble(json['averageRating'] ?? json['avgRating']),
      reviewCount: _toInt(json['reviewCount']),
      bulkPricing: (json['bulkPricing'] as List<dynamic>?)
          ?.map((e) => BulkPricingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiresPrescription: json['requiresPrescription'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'originalPrice': originalPrice,
        'discountPercentage': discountPercentage,
        'imageUrl': imageUrl,
        'images': images,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'inStock': inStock,
        'stockQuantity': stockQuantity,
        'manufacturer': manufacturer,
        'activeIngredient': activeIngredient,
        'dosageForm': dosageForm,
        'strength': strength,
        'packSize': packSize,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'requiresPrescription': requiresPrescription,
      };
}

class BulkPricingModel extends BulkPricing {
  const BulkPricingModel({
    required super.minQuantity,
    required super.maxQuantity,
    required super.pricePerUnit,
  });

  factory BulkPricingModel.fromJson(Map<String, dynamic> json) {
    return BulkPricingModel(
      minQuantity: json['minQuantity'] as int,
      maxQuantity: json['maxQuantity'] as int,
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
    );
  }
}
