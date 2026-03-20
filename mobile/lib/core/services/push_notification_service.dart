import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

class PushNotificationService {
  final ApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _messageOpenSub;

  PushNotificationService(this._apiClient);

  Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _setupToken();
        _tokenRefreshSub = _messaging.onTokenRefresh.listen(_onTokenRefresh);
        _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
        _messageOpenSub = FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
      }
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  Future<void> _setupToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        await _registerToken(_currentToken!);
      }
    } catch (e) {
      debugPrint('FCM token setup failed: $e');
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    _currentToken = token;
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiClient.post<void>(
        ApiEndpoints.registerFcmToken,
        data: {'fcmToken': token},
        parser: (_) {},
      );
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM tap: ${message.data}');
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
    } catch (e) {
      debugPrint('FCM token deletion failed: $e');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _messageOpenSub?.cancel();
  }
}
