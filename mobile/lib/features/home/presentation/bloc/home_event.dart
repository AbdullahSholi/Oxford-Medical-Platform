import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeDataFetched extends HomeEvent {
  const HomeDataFetched();
}

class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}
