import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    // connectivity_plus is unreliable on web — assume connected
    if (kIsWeb) return true;
    try {
      final result = await _connectivity.checkConnectivity();
      // connectivity_plus v5+ returns List<ConnectivityResult>
      if (result is List) {
        return !(result as List).contains(ConnectivityResult.none) || (result as List).length > 1;
      }
      return result != ConnectivityResult.none;
    } catch (_) {
      return true;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
