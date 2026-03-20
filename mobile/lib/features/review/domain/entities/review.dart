import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String productId;
  final String doctorName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final bool isVerifiedPurchase;

  const Review({
    required this.id,
    required this.productId,
    required this.doctorName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.isVerifiedPurchase = false,
  });

  @override
  List<Object?> get props => [id];
}
