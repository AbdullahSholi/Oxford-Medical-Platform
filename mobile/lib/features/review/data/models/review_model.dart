import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.productId,
    required super.doctorName,
    required super.rating,
    super.comment,
    required super.createdAt,
    super.isVerifiedPurchase,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;
    return ReviewModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      doctorName: doctor?['fullName'] as String? ?? 'Anonymous',
      rating: (json['rating'] as num).toDouble(),
      comment: json['body'] as String? ?? json['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isVerifiedPurchase: json['isVerified'] as bool? ?? false,
    );
  }
}
