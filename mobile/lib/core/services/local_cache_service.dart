import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const _prefix = 'cache_';
  static const _tsPrefix = 'cache_ts_';
  static const defaultTtl = Duration(hours: 1);

  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  Future<void> put(String key, dynamic data, {Duration ttl = defaultTtl}) async {
    final json = jsonEncode(data);
    await _prefs.setString('$_prefix$key', json);
    await _prefs.setInt('$_tsPrefix$key', DateTime.now().add(ttl).millisecondsSinceEpoch);
  }

  T? get<T>(String key, {T Function(dynamic)? parser}) {
    final expiresAt = _prefs.getInt('$_tsPrefix$key');
    if (expiresAt == null || DateTime.now().millisecondsSinceEpoch > expiresAt) {
      return null;
    }
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (parser != null) return parser(decoded);
    return decoded as T;
  }

  Future<void> remove(String key) async {
    await _prefs.remove('$_prefix$key');
    await _prefs.remove('$_tsPrefix$key');
  }

  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix) || k.startsWith(_tsPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
