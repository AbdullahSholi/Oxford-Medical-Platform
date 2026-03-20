import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../../home/domain/entities/brand.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/filter_bottom_sheet.dart';

class ProductListPage extends StatefulWidget {
  final String? categoryId;
  final String? title;

  const ProductListPage({super.key, this.categoryId, this.title});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<ProductListBloc>().add(
          ProductListFetched(categoryId: widget.categoryId),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductListBloc>().add(const ProductListNextPageFetched());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Products',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          _AppBarAction(
            icon: Icons.filter_list_rounded,
            onPressed: () => _showFilterSheet(context),
          ),
          _AppBarAction(
            icon: Icons.sort_rounded,
            onPressed: () => _showSortMenu(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          if (state is ProductListLoading) return const AppLoading();
          if (state is ProductListError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<ProductListBloc>().add(
                    ProductListFetched(categoryId: widget.categoryId),
                  ),
            );
          }
          if (state is ProductListLoaded) {
            if (state.products.isEmpty) {
              return const AppEmptyState(
                title: 'No products found',
                icon: Icons.inventory_2_outlined,
              );
            }
            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: state.products.length + (state.hasReachedMax ? 0 : 1),
              itemBuilder: (context, index) {
                if (index >= state.products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/products/${product.id}'),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...[
              (SortOption.newest, 'Newest', Icons.schedule_rounded),
              (SortOption.priceAsc, 'Price: Low to High', Icons.arrow_upward_rounded),
              (SortOption.priceDesc, 'Price: High to Low', Icons.arrow_downward_rounded),
              (SortOption.rating, 'Top Rated', Icons.star_rounded),
              (SortOption.bestSelling, 'Best Selling', Icons.trending_up_rounded),
            ].map((item) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(item.$3, color: AppColors.primary, size: 18),
              ),
              title: Text(item.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ProductListBloc>().add(ProductListSortChanged(item.$1));
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final bloc = context.read<ProductListBloc>();
    final currentState = bloc.state;
    final currentFilter = currentState is ProductListLoaded
        ? currentState.activeFilter
        : const ProductFilter();

    final homeState = context.read<HomeBloc>().state;
    final categories = homeState is HomeLoaded ? homeState.categories : const <Category>[];
    final brands = homeState is HomeLoaded ? homeState.brands : const <Brand>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        currentFilter: currentFilter,
        categories: categories,
        brands: brands,
        onApply: (filter) {
          bloc.add(ProductListFilterChanged(filter));
        },
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AppBarAction({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: AppColors.textPrimary),
          onPressed: onPressed,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }
}
