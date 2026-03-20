import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products_usecase.dart';

// Events
abstract class ProductListEvent extends Equatable {
  const ProductListEvent();
  @override
  List<Object?> get props => [];
}

class ProductListFetched extends ProductListEvent {
  final String? categoryId;
  final int page;
  const ProductListFetched({this.categoryId, this.page = 1});
  @override
  List<Object?> get props => [categoryId, page];
}

class ProductListFilterChanged extends ProductListEvent {
  final ProductFilter filter;
  const ProductListFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class ProductListSortChanged extends ProductListEvent {
  final SortOption sort;
  const ProductListSortChanged(this.sort);
  @override
  List<Object?> get props => [sort];
}

class ProductListNextPageFetched extends ProductListEvent {
  const ProductListNextPageFetched();
}

// States
abstract class ProductListState extends Equatable {
  const ProductListState();
  @override
  List<Object?> get props => [];
}

class ProductListInitial extends ProductListState {}

class ProductListLoading extends ProductListState {}

class ProductListLoaded extends ProductListState {
  final List<Product> products;
  final bool hasReachedMax;
  final int currentPage;
  final ProductFilter activeFilter;
  final SortOption? activeSort;

  const ProductListLoaded({
    required this.products,
    required this.hasReachedMax,
    required this.currentPage,
    required this.activeFilter,
    this.activeSort,
  });

  @override
  List<Object?> get props => [products, hasReachedMax, currentPage, activeFilter, activeSort];
}

class ProductListError extends ProductListState {
  final String message;
  const ProductListError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final GetProductsUseCase _getProducts;
  ProductFilter _filter = const ProductFilter();
  SortOption? _sort;

  ProductListBloc(this._getProducts) : super(ProductListInitial()) {
    on<ProductListFetched>(_onFetched);
    on<ProductListFilterChanged>(_onFilterChanged);
    on<ProductListSortChanged>(_onSortChanged);
    on<ProductListNextPageFetched>(_onNextPage);
  }

  Future<void> _onFetched(ProductListFetched event, Emitter<ProductListState> emit) async {
    emit(ProductListLoading());
    if (event.categoryId != null) {
      _filter = ProductFilter(categoryId: event.categoryId);
    }
    final result = await _getProducts(GetProductsParams(
      filter: _filter,
      sort: _sort,
      page: event.page,
    ));
    result.fold(
      (failure) => emit(ProductListError(failure.message)),
      (data) => emit(ProductListLoaded(
        products: data.items,
        hasReachedMax: !data.hasMore,
        currentPage: data.page,
        activeFilter: _filter,
        activeSort: _sort,
      )),
    );
  }

  Future<void> _onFilterChanged(ProductListFilterChanged event, Emitter<ProductListState> emit) async {
    _filter = event.filter;
    emit(ProductListLoading());
    final result = await _getProducts(GetProductsParams(filter: _filter, sort: _sort));
    result.fold(
      (failure) => emit(ProductListError(failure.message)),
      (data) => emit(ProductListLoaded(
        products: data.items,
        hasReachedMax: !data.hasMore,
        currentPage: 1,
        activeFilter: _filter,
        activeSort: _sort,
      )),
    );
  }

  Future<void> _onSortChanged(ProductListSortChanged event, Emitter<ProductListState> emit) async {
    _sort = event.sort;
    emit(ProductListLoading());
    final result = await _getProducts(GetProductsParams(filter: _filter, sort: _sort));
    result.fold(
      (failure) => emit(ProductListError(failure.message)),
      (data) => emit(ProductListLoaded(
        products: data.items,
        hasReachedMax: !data.hasMore,
        currentPage: 1,
        activeFilter: _filter,
        activeSort: _sort,
      )),
    );
  }

  Future<void> _onNextPage(ProductListNextPageFetched event, Emitter<ProductListState> emit) async {
    final currentState = state;
    if (currentState is! ProductListLoaded || currentState.hasReachedMax) return;

    final nextPage = currentState.currentPage + 1;
    final result = await _getProducts(GetProductsParams(
      filter: _filter,
      sort: _sort,
      page: nextPage,
    ));
    result.fold(
      (failure) => emit(ProductListError(failure.message)),
      (data) => emit(ProductListLoaded(
        products: [...currentState.products, ...data.items],
        hasReachedMax: !data.hasMore,
        currentPage: nextPage,
        activeFilter: _filter,
        activeSort: _sort,
      )),
    );
  }
}
