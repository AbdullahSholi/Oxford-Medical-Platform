import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
        title: Text(widget.title ?? 'Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (sort) {
              context.read<ProductListBloc>().add(ProductListSortChanged(sort));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: SortOption.newest, child: Text('Newest')),
              PopupMenuItem(value: SortOption.priceAsc, child: Text('Price: Low to High')),
              PopupMenuItem(value: SortOption.priceDesc, child: Text('Price: High to Low')),
              PopupMenuItem(value: SortOption.rating, child: Text('Top Rated')),
              PopupMenuItem(value: SortOption.bestSelling, child: Text('Best Selling')),
            ],
          ),
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
                  return const Center(child: CircularProgressIndicator());
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
