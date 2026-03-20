import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product.dart';

class FlashSale extends Equatable {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final List<Product> products;
  final bool isActive;

  const FlashSale({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.products,
    this.isActive = true,
  });

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  @override
  List<Object?> get props => [id];
}
