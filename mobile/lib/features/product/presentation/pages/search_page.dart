import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/product_card.dart';
import '../bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchBloc>().add(const SearchNextPageFetched());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.homeSearch,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (query) {
            context.read<SearchBloc>().add(SearchQueryChanged(query));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _controller.clear();
              context.read<SearchBloc>().add(const SearchCleared());
            },
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) return const AppLoading();
          if (state is SearchEmpty) {
            return AppEmptyState(
              title: context.l10n.searchNoResults,
              icon: Icons.search_off_rounded,
            );
          }
          if (state is SearchError) {
            return Center(child: Text(state.message));
          }
          if (state is SearchResults) {
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
}
