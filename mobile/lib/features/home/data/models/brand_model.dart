import '../../domain/entities/brand.dart';

class BrandModel extends Brand {
  const BrandModel({
    required super.id,
    required super.name,
    required super.slug,
    super.logoUrl,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logoUrl'] as String?,
    );
  }
}
