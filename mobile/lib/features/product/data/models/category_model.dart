import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.imageUrl,
    super.iconUrl,
    super.parentId,
    super.productCount,
    super.subcategories,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      iconUrl: json['iconUrl'] as String?,
      parentId: json['parentId'] as String?,
      productCount: json['productCount'] as int? ?? 0,
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
