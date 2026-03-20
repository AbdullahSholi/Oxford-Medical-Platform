import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

class SocketService {
  io.Socket? _socket;
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;
  Stream<Map<String, dynamic>> get onOrderUpdate => _orderUpdateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    disconnect();

    final baseUrl = kDebugMode
        ? AppConstants.devBaseUrl.replaceAll('/api/v1', '')
        : AppConstants.baseUrl.replaceAll('/api/v1', '');

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected');
    });

    _socket!.on('notification:new', (data) {
      if (data is Map<String, dynamic>) {
        _notificationController.add(data);
      } else if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('order:status-updated', (data) {
      if (data is Map<String, dynamic>) {
        _orderUpdateController.add(data);
      } else if (data is Map) {
        _orderUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connection error: $err');
    });
  }

  void trackOrder(String orderId) {
    _socket?.emit('track:order', orderId);
  }

  void untrackOrder(String orderId) {
    _socket?.emit('untrack:order', orderId);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _orderUpdateController.close();
  }
}
