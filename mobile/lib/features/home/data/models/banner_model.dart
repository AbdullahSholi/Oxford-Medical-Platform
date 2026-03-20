import '../../domain/entities/banner.dart';

class BannerModel extends PromoBanner {
  const BannerModel({
    required super.id,
    required super.title,
    required super.imageUrl,
    super.actionUrl,
    super.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      actionUrl: json['actionUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
