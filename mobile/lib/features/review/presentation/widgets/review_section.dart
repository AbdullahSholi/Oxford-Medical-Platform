import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/review.dart';
import '../bloc/review_bloc.dart';

class ReviewSection extends StatelessWidget {
  final String productId;
  final double avgRating;
  final int reviewCount;
  const ReviewSection({super.key, required this.productId, required this.avgRating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewBloc, ReviewState>(
      builder: (context, state) {
        if (state is ReviewLoading) {
          return const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator()));
        }
        if (state is ReviewsLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reviews (${state.totalCount})', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () => _showAddReviewSheet(context),
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Write Review'),
                  ),
                ],
              ),

              // Rating summary
              if (state.totalCount > 0) ...[
                Row(
                  children: [
                    Text(state.avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                    AppSpacing.horizontalGapSm,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StarRating(rating: state.avgRating),
                        Text('${state.totalCount} review${state.totalCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                AppSpacing.verticalGapMd,
              ],

              // Review list
              if (state.reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('No reviews yet. Be the first!', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ...state.reviews.take(5).map((review) => _ReviewCard(review: review)),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    final bloc = context.read<ReviewBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _AddReviewSheet(productId: productId),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRating({required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) return Icon(Icons.star_rounded, color: Colors.amber, size: size);
        if (i < rating) return Icon(Icons.star_half_rounded, color: Colors.amber, size: size);
        return Icon(Icons.star_outline_rounded, color: Colors.amber, size: size);
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text(review.doctorName.isNotEmpty ? review.doctorName[0] : '?', style: const TextStyle(fontSize: 12, color: Colors.white))),
              AppSpacing.horizontalGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review.doctorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (review.isVerifiedPurchase) ...[
                          AppSpacing.horizontalGapSm,
                          const Icon(Icons.verified, color: AppColors.success, size: 14),
                        ],
                      ],
                    ),
                    Text(Formatters.timeAgo(review.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ),
              _StarRating(rating: review.rating, size: 14),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const Divider(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AddReviewSheet extends StatefulWidget {
  final String productId;
  const _AddReviewSheet({required this.productId});

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  int _rating = 0;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() { _titleController.dispose(); _bodyController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitSuccess) Navigator.pop(context);
        if (state is ReviewError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write a Review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            AppSpacing.verticalGapLg,
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber, size: 36,
                    ),
                  ),
                )),
              ),
            ),
            AppSpacing.verticalGapLg,
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title (optional)', border: OutlineInputBorder()),
            ),
            AppSpacing.verticalGapMd,
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Your review (optional)', border: OutlineInputBorder()),
            ),
            AppSpacing.verticalGapLg,
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<ReviewBloc, ReviewState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: _rating == 0 || state is ReviewSubmitting ? null : () {
                      context.read<ReviewBloc>().add(ReviewSubmitted(
                        productId: widget.productId,
                        rating: _rating,
                        title: _titleController.text.trim(),
                        body: _bodyController.text.trim(),
                      ));
                    },
                    child: Text(state is ReviewSubmitting ? 'Submitting...' : 'Submit Review'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
