import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../review/domain/entities/review.dart';
import '../bloc/product_detail_bloc.dart';

class ReviewsTab extends StatelessWidget {
  final String productId;

  const ReviewsTab({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailBloc, ProductDetailState>(
      listener: (context, state) {
        if (state is ProductDetailLoaded && state.reviewSubmitted) {
          context.showSnackBar('Review submitted successfully!');
        }
        if (state is ProductDetailLoaded && state.reviewError != null) {
          context.showSnackBar(state.reviewError!, isError: true);
        }
      },
      builder: (context, state) {
        if (state is! ProductDetailLoaded) return const SizedBox.shrink();

        if (!state.reviewsFetched && !state.reviewsLoading) {
          // Auto-fetch reviews on first display
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ProductDetailBloc>().add(ProductReviewsFetched(productId));
          });
        }

        if (state.reviewsLoading && state.reviews.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Write review button
              OutlinedButton.icon(
                onPressed: () => _showWriteReviewDialog(context, productId),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Write a Review'),
              ),
              AppSpacing.verticalGapMd,
              if (state.reviews.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'No reviews yet. Be the first to review!',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...state.reviews.map((review) => _ReviewCard(review: review)),
            ],
          ),
        );
      },
    );
  }

  void _showWriteReviewDialog(BuildContext context, String productId) {
    int selectedRating = 5;
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Write a Review',
                    style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  AppSpacing.verticalGapLg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.warning,
                          size: 36,
                        ),
                        onPressed: () =>
                            setState(() => selectedRating = index + 1),
                      );
                    }),
                  ),
                  AppSpacing.verticalGapMd,
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSpacing.verticalGapMd,
                  TextField(
                    controller: bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Your review (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  AppSpacing.verticalGapLg,
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductDetailBloc>().add(
                            ProductReviewSubmitted(
                              productId: productId,
                              rating: selectedRating,
                              title: titleController.text.isNotEmpty
                                  ? titleController.text
                                  : null,
                              body: bodyController.text.isNotEmpty
                                  ? bodyController.text
                                  : null,
                            ),
                          );
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Submit Review'),
                  ),
                  AppSpacing.verticalGapLg,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    review.doctorName.isNotEmpty
                        ? review.doctorName[0].toUpperCase()
                        : '?',
                  ),
                ),
                AppSpacing.horizontalGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.doctorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      RatingStars(rating: review.rating, size: 14),
                    ],
                  ),
                ),
                if (review.isVerifiedPurchase)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              AppSpacing.verticalGapSm,
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }
}
