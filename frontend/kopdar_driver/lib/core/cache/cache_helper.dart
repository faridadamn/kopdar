import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple offline cache helper using SharedPreferences.
/// Caches API responses with TTL for offline access.
class CacheHelper {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'CacheHelper not initialized. Call init() first.');
    return _prefs!;
  }

  // ── Generic cache methods ──

  /// Cache a JSON-serializable object with TTL.
  static Future<void> cacheJson(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final entry = {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
      'expires_at':
          DateTime.now().add(ttl).toIso8601String(),
    };
    await _p.setString('cache_$key', jsonEncode(entry));
  }

  /// Get cached JSON if not expired.
  static Map<String, dynamic>? getCachedJson(String key) {
    final raw = _p.getString('cache_$key');
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(entry['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        // Expired — remove
        _p.remove('cache_$key');
        return null;
      }
      return entry['data'] as Map<String, dynamic>;
    } catch (_) {
      _p.remove('cache_$key');
      return null;
    }
  }

  /// Cache a list of JSON objects.
  static Future<void> cacheJsonList(
    String key,
    List<Map<String, dynamic>> data, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final entry = {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(ttl).toIso8601String(),
    };
    await _p.setString('cache_$key', jsonEncode(entry));
  }

  /// Get cached JSON list if not expired.
  static List<Map<String, dynamic>>? getCachedJsonList(String key) {
    final raw = _p.getString('cache_$key');
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(entry['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        _p.remove('cache_$key');
        return null;
      }
      final data = entry['data'] as List;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      _p.remove('cache_$key');
      return null;
    }
  }

  /// Remove a specific cache entry.
  static Future<void> removeCache(String key) async {
    await _p.remove('cache_$key');
  }

  /// Clear all cache entries.
  static Future<void> clearAllCache() async {
    final keys = _p.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await _p.remove(key);
    }
  }

  // ── Convenience methods for common data ──

  static Future<void> cacheProfile(Map<String, dynamic> data) =>
      cacheJson('profile', data, ttl: const Duration(hours: 24));

  static Map<String, dynamic>? getCachedProfile() =>
      getCachedJson('profile');

  static Future<void> cacheVehicles(List<Map<String, dynamic>> data) =>
      cacheJsonList('vehicles', data, ttl: const Duration(hours: 24));

  static List<Map<String, dynamic>>? getCachedVehicles() =>
      getCachedJsonList('vehicles');

  static Future<void> cacheDashboard(Map<String, dynamic> data) =>
      cacheJson('dashboard', data, ttl: const Duration(minutes: 30));

  static Map<String, dynamic>? getCachedDashboard() =>
      getCachedJson('dashboard');
}
