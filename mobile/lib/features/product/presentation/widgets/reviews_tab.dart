import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading.dart';
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ProductDetailBloc>().add(ProductReviewsFetched(productId));
          });
        }

        if (state.reviewsLoading && state.reviews.isEmpty) {
          return const AppLoading();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Write review button
              GestureDetector(
                onTap: () => _showWriteReviewDialog(context, productId),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Write a Review',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalGapMd,
              if (state.reviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.rate_review_outlined, size: 32, color: AppColors.textHint),
                        ),
                        AppSpacing.verticalGapMd,
                        const Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Be the first to review!',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
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
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Write a Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  AppSpacing.verticalGapLg,
                  // Star rating
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
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
                  ),
                  AppSpacing.verticalGapLg,
                  AppTextField(
                    controller: titleController,
                    label: 'Title (optional)',
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                  AppSpacing.verticalGapLg,
                  AppTextField(
                    controller: bodyController,
                    label: 'Your review (optional)',
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    maxLines: 3,
                  ),
                  AppSpacing.verticalGapXl,
                  AppButton(
                    label: 'Submit Review',
                    variant: AppButtonVariant.gradient,
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
                  ),
                  const SizedBox(height: 16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    review.doctorName.isNotEmpty
                        ? review.doctorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              AppSpacing.horizontalGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.doctorName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    RatingStars(rating: review.rating, size: 14),
                  ],
                ),
              ),
              if (review.isVerifiedPurchase)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                      SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            AppSpacing.verticalGapSm,
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
