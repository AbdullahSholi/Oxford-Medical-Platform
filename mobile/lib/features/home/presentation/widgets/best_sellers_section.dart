import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
              Text(
                context.l10n.homeBestSellers,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              TextButton(
                onPressed: () => context.push('/products?sort=bestSelling'),
                child: Text(context.l10n.homeViewAll),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapSm,
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
