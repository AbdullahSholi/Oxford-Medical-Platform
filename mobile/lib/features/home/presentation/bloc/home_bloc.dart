import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_home_data_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeDataUseCase _getHomeData;

  HomeBloc(this._getHomeData) : super(const HomeInitial()) {
    on<HomeDataFetched>(_onDataFetched);
    on<HomeRefreshed>(_onRefreshed);
  }

  Future<void> _onDataFetched(
    HomeDataFetched event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    await _fetchData(emit);
  }

  Future<void> _onRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<HomeState> emit) async {
    final result = await _getHomeData(const NoParams());
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (data) => emit(HomeLoaded(
        banners: data.banners,
        flashSale: data.flashSale,
        bestSellers: data.bestSellers,
        categories: data.categories,
        brands: data.brands,
      )),
    );
  }
}
