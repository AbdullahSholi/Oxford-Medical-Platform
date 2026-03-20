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
                // Modern image header
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  actions: [
                    BlocSelector<WishlistBloc, WishlistState, bool>(
                      selector: (wState) =>
                          wState is WishlistLoaded && wState.productIds.contains(product.id),
                      builder: (context, inWishlist) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            boxShadow: AppSpacing.shadowSm,
                          ),
                          child: IconButton(
                            icon: Icon(
                              inWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: inWishlist ? AppColors.error : AppColors.textPrimary,
                              size: 20,
                            ),
                            onPressed: () {
                              context.read<WishlistBloc>().add(WishlistItemToggled(product.id));
                              context.showSnackBar('Wishlist updated');
                            },
                          ),
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: AppColors.surfaceVariant,
                      child: PageView.builder(
                        itemCount: product.images.isEmpty ? 1 : product.images.length,
                        itemBuilder: (_, index) => AppCachedImage(
                          imageUrl: product.images.isEmpty
                              ? product.imageUrl
                              : product.images[index],
                          width: double.infinity,
                          height: 320,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge
                          if (product.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                              child: Text(
                                product.categoryName!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          AppSpacing.verticalGapMd,
                          // Product name
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.3,
                            ),
                          ),
                          AppSpacing.verticalGapMd,
                          // Rating
                          Row(
                            children: [
                              RatingStars(rating: product.averageRating),
                              AppSpacing.horizontalGapSm,
                              Text(
                                '${product.averageRating.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                ' (${product.reviewCount} reviews)',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.verticalGapLg,
                          // Price section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              boxShadow: AppSpacing.shadowSm,
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Formatters.price(product.price),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    if (product.originalPrice != null &&
                                        product.originalPrice != product.price)
                                      Row(
                                        children: [
                                          Text(
                                            Formatters.price(product.originalPrice!),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: AppColors.textHint,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.errorLight,
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                            ),
                                            child: Text(
                                              Formatters.discount(product.originalPrice!, product.price),
                                              style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                // Stock status
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: product.inStock
                                        ? AppColors.successLight
                                        : AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        product.inStock
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        size: 14,
                                        color: product.inStock ? AppColors.success : AppColors.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.inStock
                                            ? context.l10n.productInStock
                                            : context.l10n.productOutOfStock,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: product.inStock ? AppColors.success : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.verticalGapXl,
                          // Tabs
                          DefaultTabController(
                            length: 3,
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                  child: TabBar(
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    dividerColor: Colors.transparent,
                                    indicator: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor: AppColors.textSecondary,
                                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    padding: const EdgeInsets.all(4),
                                    tabs: [
                                      Tab(text: context.l10n.productDescription, height: 36),
                                      Tab(text: context.l10n.productMedicalInfo, height: 36),
                                      Tab(text: context.l10n.productReviews, height: 36),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 300,
                                  child: TabBarView(
                                    children: [
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                                        child: Text(
                                          product.description,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                            height: 1.6,
                                          ),
                                        ),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            AppSpacing.verticalGapMd,
                            BulkPricingTable(pricing: product.bulkPricing!),
                          ],
                          // Extra padding for bottom bar
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      // Floating add-to-cart bar
      bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is! ProductDetailLoaded) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Price recap
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        Formatters.price(state.product.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: context.l10n.productAddToCart,
                      icon: Icons.shopping_cart_outlined,
                      variant: AppButtonVariant.gradient,
                      onPressed: state.product.inStock
                          ? () {
                              context.read<CartBloc>().add(
                                    CartItemAdded(productId: state.product.id),
                                  );
                              context.showSnackBar('Added to cart');
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
