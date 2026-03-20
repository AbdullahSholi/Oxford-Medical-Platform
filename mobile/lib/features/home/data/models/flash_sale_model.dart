import '../../../product/data/models/product_model.dart';
import '../../domain/entities/flash_sale.dart';

class FlashSaleModel extends FlashSale {
  const FlashSaleModel({
    required super.id,
    required super.title,
    required super.startTime,
    required super.endTime,
    required super.products,
    super.isActive,
  });

  factory FlashSaleModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
