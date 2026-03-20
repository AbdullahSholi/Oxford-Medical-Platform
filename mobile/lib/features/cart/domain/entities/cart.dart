import 'package:equatable/equatable.dart';

class Cart extends Equatable {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String? couponCode;

  const Cart({
    required this.id,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    this.couponCode,
  });

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [id, items, total];
}

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double total;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  @override
  List<Object?> get props => [id, productId, quantity];
}
