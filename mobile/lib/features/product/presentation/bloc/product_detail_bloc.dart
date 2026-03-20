import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_product_detail_usecase.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../../review/domain/entities/review.dart';

// Events
abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override
  List<Object?> get props => [];
}

class ProductDetailFetched extends ProductDetailEvent {
  final String id;
  const ProductDetailFetched(this.id);
  @override
  List<Object?> get props => [id];
}

class ProductReviewsFetched extends ProductDetailEvent {
  final String productId;
  const ProductReviewsFetched(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ProductReviewSubmitted extends ProductDetailEvent {
  final String productId;
  final int rating;
  final String? title;
  final String? body;
  const ProductReviewSubmitted({
    required this.productId,
    required this.rating,
    this.title,
    this.body,
  });
  @override
  List<Object?> get props => [productId, rating, title, body];
}

// States
abstract class ProductDetailState extends Equatable {
  const ProductDetailState();
  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}
class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final Product product;
  final List<Review> reviews;
  final bool reviewsLoading;
  final bool reviewsFetched;
  final String? reviewError;
  final bool reviewSubmitted;

  const ProductDetailLoaded(
    this.product, {
    this.reviews = const [],
    this.reviewsLoading = false,
    this.reviewsFetched = false,
    this.reviewError,
    this.reviewSubmitted = false,
  });

  ProductDetailLoaded copyWith({
    Product? product,
    List<Review>? reviews,
    bool? reviewsLoading,
    bool? reviewsFetched,
    String? reviewError,
    bool? reviewSubmitted,
  }) {
    return ProductDetailLoaded(
      product ?? this.product,
      reviews: reviews ?? this.reviews,
      reviewsLoading: reviewsLoading ?? this.reviewsLoading,
      reviewsFetched: reviewsFetched ?? this.reviewsFetched,
      reviewError: reviewError,
      reviewSubmitted: reviewSubmitted ?? this.reviewSubmitted,
    );
  }

  @override
  List<Object?> get props => [product, reviews, reviewsLoading, reviewsFetched, reviewError, reviewSubmitted];
}

class ProductDetailError extends ProductDetailState {
  final String message;
  const ProductDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductDetailUseCase _getProductDetail;
  final ProductRemoteDataSource _remote;

  ProductDetailBloc(this._getProductDetail, this._remote) : super(ProductDetailInitial()) {
    on<ProductDetailFetched>(_onFetched);
    on<ProductReviewsFetched>(_onReviewsFetched);
    on<ProductReviewSubmitted>(_onReviewSubmitted);
  }

  Future<void> _onFetched(ProductDetailFetched event, Emitter<ProductDetailState> emit) async {
    emit(ProductDetailLoading());
    final result = await _getProductDetail(event.id);
    result.fold(
      (failure) => emit(ProductDetailError(failure.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }

  Future<void> _onReviewsFetched(ProductReviewsFetched event, Emitter<ProductDetailState> emit) async {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(reviewsLoading: true));
    try {
      final reviews = await _remote.getProductReviews(event.productId);
      emit(current.copyWith(reviews: reviews, reviewsLoading: false, reviewsFetched: true));
    } catch (e) {
      emit(current.copyWith(reviewsLoading: false, reviewsFetched: true, reviewError: e.toString()));
    }
  }

  Future<void> _onReviewSubmitted(ProductReviewSubmitted event, Emitter<ProductDetailState> emit) async {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(reviewsLoading: true));
    try {
      await _remote.createReview(
        productId: event.productId,
        rating: event.rating,
        title: event.title,
        body: event.body,
      );
      final reviews = await _remote.getProductReviews(event.productId);
      emit(current.copyWith(reviews: reviews, reviewsLoading: false, reviewSubmitted: true));
    } catch (e) {
      final message = e is ServerException ? e.message : 'Failed to submit review';
      emit(current.copyWith(reviewsLoading: false, reviewError: message));
    }
  }
}
