import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../bloc/product_detail_bloc.dart';
import '../widgets/bulk_pricing_table.dart';
import '../widgets/medical_details_tab.dart';
import '../widgets/reviews_tab.dart';

class ProductDetailPage extends StatelessWidget {
  final String id;

  const ProductDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailLoading) return const AppLoading();
          if (state is ProductDetailError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context
                  .read<ProductDetailBloc>()
                  .add(ProductDetailFetched(id)),
            );
          }
          if (state is ProductDetailLoaded) {
            final product = state.product;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: PageView.builder(
                      itemCount: product.images.isEmpty ? 1 : product.images.length,
                      itemBuilder: (_, index) => AppCachedImage(
                        imageUrl: product.images.isEmpty
                            ? product.imageUrl
                            : product.images[index],
                        width: double.infinity,
                        height: 300,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border_rounded),
                      onPressed: () {
                        final state = context.read<ProductDetailBloc>().state;
                        if (state is ProductDetailLoaded) {
                          context.read<WishlistBloc>().add(WishlistItemToggled(state.product.id));
                          context.showSnackBar('Wishlist updated');
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.categoryName != null)
                          Text(
                            product.categoryName!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        AppSpacing.verticalGapSm,
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        AppSpacing.verticalGapMd,
                        Row(
                          children: [
                            RatingStars(rating: product.averageRating),
                            AppSpacing.horizontalGapSm,
                            Text(
                              '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount})',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalGapLg,
                        Row(
                          children: [
                            Text(
                              Formatters.price(product.price),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (product.originalPrice != null &&
                                product.originalPrice != product.price) ...[
                              AppSpacing.horizontalGapMd,
                              Text(
                                Formatters.price(product.originalPrice!),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              AppSpacing.horizontalGapSm,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  Formatters.discount(product.originalPrice!, product.price),
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        AppSpacing.verticalGapSm,
                        Row(
                          children: [
                            Icon(
                              product.inStock
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 16,
                              color: product.inStock
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            AppSpacing.horizontalGapXs,
                            Text(
                              product.inStock
                                  ? context.l10n.productInStock
                                  : context.l10n.productOutOfStock,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: product.inStock
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalGapXl,
                        // Tabs
                        DefaultTabController(
                          length: 3,
                          child: Column(
                            children: [
                              TabBar(
                                tabs: [
                                  Tab(text: context.l10n.productDescription),
                                  Tab(text: context.l10n.productMedicalInfo),
                                  Tab(text: context.l10n.productReviews),
                                ],
                              ),
                              SizedBox(
                                height: 300,
                                child: TabBarView(
                                  children: [
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                                      child: Text(product.description),
                                    ),
                                    MedicalDetailsTab(product: product),
                                    ReviewsTab(productId: product.id),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (product.bulkPricing != null &&
                            product.bulkPricing!.isNotEmpty) ...[
                          AppSpacing.verticalGapXl,
                          Text(
                            context.l10n.productBulkPricing,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          AppSpacing.verticalGapMd,
                          BulkPricingTable(pricing: product.bulkPricing!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is! ProductDetailLoaded) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.l10n.productAddToCart,
                      icon: Icons.shopping_cart_outlined,
                      onPressed: state.product.inStock
                          ? () {
                              context.read<CartBloc>().add(
                                    CartItemAdded(productId: state.product.id),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
