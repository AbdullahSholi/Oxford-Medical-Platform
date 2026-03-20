import '../../domain/entities/order.dart';

double _toDouble(dynamic v) =>
    v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.items,
    required super.status,
    required super.subtotal,
    super.discount,
    super.deliveryFee,
    required super.total,
    super.shippingAddress,
    required super.createdAt,
    super.estimatedDelivery,
    super.trackingNumber,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final address = json['deliveryAddress'];
    String? shippingStr;
    if (address is Map) {
      shippingStr = [address['streetAddress'], address['city']]
          .where((s) => s != null && s.toString().isNotEmpty)
          .join(', ');
    } else if (address is String) {
      shippingStr = address;
    }
    shippingStr ??= json['shippingAddress'] as String?;

    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discountAmount'] ?? json['discount']),
      deliveryFee: _toDouble(json['deliveryFee']),
      total: _toDouble(json['total']),
      shippingAddress: shippingStr,
      createdAt: DateTime.parse(json['createdAt'] as String),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
      trackingNumber: json['trackingNumber'] as String?,
    );
  }

  static OrderStatus _parseStatus(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.productImage,
    required super.price,
    required super.quantity,
    required super.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final price = _toDouble(json['unitPrice'] ?? json['price']);
    final qty = json['quantity'] as int? ?? 1;
    return OrderItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String? ?? '',
      price: price,
      quantity: qty,
      total: _toDouble(json['totalPrice'] ?? json['total']),
    );
  }
}
