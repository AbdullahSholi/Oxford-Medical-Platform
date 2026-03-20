import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../product/domain/entities/product.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

class BestSellersSection extends StatelessWidget {
  final List<Product> products;

  const BestSellersSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.pagePadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.homeBestSellers,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/products?sort=bestSelling'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.homeViewAll,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapMd,
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: products.length > 6 ? 6 : products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return BlocSelector<WishlistBloc, WishlistState, bool>(
              selector: (state) => state is WishlistLoaded && state.productIds.contains(product.id),
              builder: (context, inWishlist) {
                return ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  isInWishlist: inWishlist,
                  onToggleWishlist: () => context.read<WishlistBloc>().add(WishlistItemToggled(product.id)),
                  onTap: () => context.push('/products/${product.id}'),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
