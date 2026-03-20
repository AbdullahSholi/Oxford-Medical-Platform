import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/countdown_timer.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../domain/entities/flash_sale.dart';

class FlashSaleSection extends StatelessWidget {
  final FlashSale flashSale;

  const FlashSaleSection({super.key, required this.flashSale});

  @override
  Widget build(BuildContext context) {
    if (!flashSale.isOngoing || flashSale.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.pagePadding,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.homeFlashSale,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: CountdownTimer(endTime: flashSale.endTime),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.verticalGapMd,
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: flashSale.products.length,
            separatorBuilder: (_, __) => AppSpacing.horizontalGapMd,
            itemBuilder: (context, index) {
              final product = flashSale.products[index];
              return SizedBox(
                width: 160,
                child: BlocSelector<WishlistBloc, WishlistState, bool>(
                  selector: (state) => state is WishlistLoaded && state.productIds.contains(product.id),
                  builder: (context, inWishlist) {
                    return ProductCard(
                      key: ValueKey(product.id),
                      product: product,
                      isInWishlist: inWishlist,
                      onToggleWishlist: () => context.read<WishlistBloc>().add(WishlistItemToggled(product.id)),
                      onTap: () {},
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
