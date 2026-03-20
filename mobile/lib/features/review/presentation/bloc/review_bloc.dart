import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/review_model.dart';
import '../../domain/entities/review.dart';

// Events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();
  @override
  List<Object?> get props => [];
}

class ReviewsFetched extends ReviewEvent {
  final String productId;
  const ReviewsFetched(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ReviewSubmitted extends ReviewEvent {
  final String productId;
  final int rating;
  final String? title;
  final String? body;
  final String? orderItemId;
  const ReviewSubmitted({required this.productId, required this.rating, this.title, this.body, this.orderItemId});
  @override
  List<Object?> get props => [productId, rating, title, body];
}

// States
abstract class ReviewState extends Equatable {
  const ReviewState();
  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}
class ReviewLoading extends ReviewState {}
class ReviewsLoaded extends ReviewState {
  final List<Review> reviews;
  final double avgRating;
  final int totalCount;
  const ReviewsLoaded({required this.reviews, required this.avgRating, required this.totalCount});
  @override
  List<Object?> get props => [reviews];
}
class ReviewSubmitting extends ReviewState {}
class ReviewSubmitSuccess extends ReviewState {}
class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ApiClient _apiClient;

  ReviewBloc(this._apiClient) : super(ReviewInitial()) {
    on<ReviewsFetched>(_onFetched);
    on<ReviewSubmitted>(_onSubmitted);
  }

  Future<void> _onFetched(ReviewsFetched event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.productReviews(event.productId),
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is List) return {'data': data, 'avgRating': 0.0, 'totalCount': data.length};
        return {'data': [], 'avgRating': 0.0, 'totalCount': 0};
      },
    );
    if (response.success && response.data != null) {
      final rawData = response.data!;
      final rawList = rawData['data'] ?? rawData['reviews'] ?? [];
      final reviews = (rawList as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      emit(ReviewsLoaded(
        reviews: reviews,
        avgRating: (rawData['avgRating'] as num?)?.toDouble() ?? 0.0,
        totalCount: rawData['totalCount'] as int? ?? reviews.length,
      ));
    } else {
      emit(ReviewError(response.error?.message ?? 'Failed to load reviews'));
    }
  }

  Future<void> _onSubmitted(ReviewSubmitted event, Emitter<ReviewState> emit) async {
    emit(ReviewSubmitting());
    final response = await _apiClient.post<void>(
      ApiEndpoints.reviews,
      data: {
        'productId': event.productId,
        'rating': event.rating,
        if (event.title != null && event.title!.isNotEmpty) 'title': event.title,
        if (event.body != null && event.body!.isNotEmpty) 'body': event.body,
        if (event.orderItemId != null) 'orderItemId': event.orderItemId,
      },
      parser: (_) {},
    );
    if (response.success) {
      emit(ReviewSubmitSuccess());
      // Re-fetch reviews
      add(ReviewsFetched(event.productId));
    } else {
      emit(ReviewError(response.error?.message ?? 'Failed to submit review'));
    }
  }
}
