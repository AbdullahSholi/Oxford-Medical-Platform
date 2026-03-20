import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/app_notification.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsFetched extends NotificationEvent { const NotificationsFetched(); }
class NotificationMarkedRead extends NotificationEvent {
  final String id;
  const NotificationMarkedRead(this.id);
  @override
  List<Object?> get props => [id];
}
class NotificationsAllMarkedRead extends NotificationEvent { const NotificationsAllMarkedRead(); }
class NotificationDeleted extends NotificationEvent {
  final String id;
  const NotificationDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}
class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  const NotificationLoaded(this.notifications);
  @override
  List<Object?> get props => [notifications];
}
class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiClient _apiClient;

  NotificationBloc(this._apiClient) : super(NotificationInitial()) {
    on<NotificationsFetched>(_onFetched);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationsAllMarkedRead>(_onAllMarkedRead);
    on<NotificationDeleted>(_onDeleted);
  }

  Future<void> _onFetched(NotificationsFetched event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    final response = await _apiClient.get<List<AppNotification>>(
      ApiEndpoints.notifications,
      parser: (data) => (data as List).map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    if (response.success) {
      emit(NotificationLoaded(response.data!));
    } else {
      emit(NotificationError(response.error?.message ?? 'Failed to load notifications'));
    }
  }

  Future<void> _onMarkedRead(NotificationMarkedRead event, Emitter<NotificationState> emit) async {
    await _apiClient.patch<void>(ApiEndpoints.notificationMarkRead(event.id), parser: (_) {});
    add(const NotificationsFetched());
  }

  Future<void> _onAllMarkedRead(NotificationsAllMarkedRead event, Emitter<NotificationState> emit) async {
    await _apiClient.post<void>(ApiEndpoints.notificationsReadAll, parser: (_) {});
    add(const NotificationsFetched());
  }

  Future<void> _onDeleted(NotificationDeleted event, Emitter<NotificationState> emit) async {
    await _apiClient.delete<void>(ApiEndpoints.notificationById(event.id), parser: (_) {});
    add(const NotificationsFetched());
  }
}
