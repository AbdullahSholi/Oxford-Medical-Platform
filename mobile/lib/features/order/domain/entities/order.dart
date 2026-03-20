import 'package:equatable/equatable.dart';

enum OrderStatus { pending, confirmed, processing, shipped, delivered, cancelled }

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String? shippingAddress;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.status,
    required this.subtotal,
    this.discount = 0,
    this.deliveryFee = 0,
    required this.total,
    this.shippingAddress,
    required this.createdAt,
    this.estimatedDelivery,
    this.trackingNumber,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [id];
}

class OrderItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double total;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  @override
  List<Object?> get props => [id];
}
