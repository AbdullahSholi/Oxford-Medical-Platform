import '../../domain/entities/cart.dart';

class CartModel extends Cart {
  const CartModel({
    required super.id,
    required super.items,
    required super.subtotal,
    super.discount,
    required super.total,
    super.couponCode,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    // Backend may not include subtotal/total; compute from items
    double _toDouble(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    final subtotal = _toDouble(json['subtotal']) > 0
        ? _toDouble(json['subtotal'])
        : items.fold(0.0, (sum, item) => sum + item.total);
    final discount = _toDouble(json['discount']);
    final total = _toDouble(json['total']) > 0
        ? _toDouble(json['total'])
        : subtotal - discount;
    return CartModel(
      id: json['id'] as String,
      items: items,
      subtotal: subtotal,
      discount: discount,
      total: total,
      couponCode: json['couponCode'] as String?,
    );
  }
}

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.productImage,
    required super.price,
    required super.quantity,
    required super.total,
  });

  static String? _extractImage(Map<String, dynamic>? product) {
    if (product == null) return null;
    if (product['imageUrl'] != null) return product['imageUrl'] as String;
    final images = product['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final first = images[0];
      if (first is Map) return first['url'] as String?;
      if (first is String) return first;
    }
    return null;
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    final qty = json['quantity'] as int? ?? 1;
    final product = json['product'] as Map<String, dynamic>?;
    final price = _toDouble(json['price'] ?? json['unitPrice'] ?? product?['salePrice'] ?? product?['price']);
    return CartItemModel(
      id: json['id'] as String,
      productId: (json['productId'] ?? product?['id'] ?? '') as String,
      productName: (json['productName'] ?? product?['name'] ?? '') as String,
      productImage: (json['productImage'] ?? _extractImage(product) ?? '') as String,
      price: price,
      quantity: qty,
      total: _toDouble(json['total']) > 0 ? _toDouble(json['total']) : price * qty,
    );
  }
}
