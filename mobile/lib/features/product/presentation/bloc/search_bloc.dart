import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/search_products_usecase.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchNextPageFetched extends SearchEvent {
  const SearchNextPageFetched();
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

// States
abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}

class SearchResults extends SearchState {
  final List<Product> products;
  final String query;
  final bool hasReachedMax;
  final int currentPage;

  const SearchResults({
    required this.products,
    required this.query,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [products, query, hasReachedMax, currentPage];
}

class SearchEmpty extends SearchState {
  final String query;
  const SearchEmpty(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchProductsUseCase _searchProducts;

  SearchBloc(this._searchProducts) : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: _debounce(const Duration(milliseconds: 500)),
    );
    on<SearchNextPageFetched>(_onNextPage);
    on<SearchCleared>(_onCleared);
  }

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }
    emit(SearchLoading());
    final result = await _searchProducts(SearchProductsParams(query: query));
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (data) {
        if (data.items.isEmpty) {
          emit(SearchEmpty(query));
        } else {
          emit(SearchResults(
            products: data.items,
            query: query,
            hasReachedMax: !data.hasMore,
            currentPage: 1,
          ));
        }
      },
    );
  }

  Future<void> _onNextPage(SearchNextPageFetched event, Emitter<SearchState> emit) async {
    final currentState = state;
    if (currentState is! SearchResults || currentState.hasReachedMax) return;

    final nextPage = currentState.currentPage + 1;
    final result = await _searchProducts(
      SearchProductsParams(query: currentState.query, page: nextPage),
    );
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (data) {
        emit(SearchResults(
          products: [...currentState.products, ...data.items],
          query: currentState.query,
          hasReachedMax: !data.hasMore,
          currentPage: nextPage,
        ));
      },
    );
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(SearchInitial());
  }

  EventTransformer<T> _debounce<T>(Duration duration) {
    return (events, mapper) => events
        .transform(_DebounceStreamTransformer(duration))
        .asyncExpand(mapper);
  }
}

class _DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  const _DebounceStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    Timer? timer;
    return stream.transform(StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        timer?.cancel();
        timer = Timer(duration, () => sink.add(data));
      },
    ));
  }
}
