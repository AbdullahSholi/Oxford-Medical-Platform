import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product.dart';

class WishlistItem extends Equatable {
  final String id;
  final Product product;
  final DateTime addedAt;

  const WishlistItem({required this.id, required this.product, required this.addedAt});

  @override
  List<Object?> get props => [id];
}
