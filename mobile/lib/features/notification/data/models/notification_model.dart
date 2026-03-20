import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id, required super.title, required super.body,
    required super.type, super.isRead, required super.createdAt, super.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    type: json['type'] as String? ?? 'general',
    isRead: json['isRead'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    data: json['data'] as Map<String, dynamic>?,
  );
}
