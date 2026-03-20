import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../domain/entities/product.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ScrollController? scrollController;

  const ProductGrid({
    super.key,
    required this.products,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return BlocBuilder<WishlistBloc, WishlistState>(
          builder: (context, wishlistState) {
            final inWishlist = wishlistState is WishlistLoaded && wishlistState.productIds.contains(product.id);
            return ProductCard(
              product: product,
              isInWishlist: inWishlist,
              onToggleWishlist: () => context.read<WishlistBloc>().add(WishlistItemToggled(product.id)),
              onTap: () => context.push('/products/${product.id}'),
            );
          },
        );
      },
    );
  }
}
