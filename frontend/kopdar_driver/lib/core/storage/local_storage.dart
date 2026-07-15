import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String
  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // Int
  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Bool
  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Double
  static Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // List<String>
  static Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // Remove
  static Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  // Clear all
  static Future<bool> clear() {
    return _prefs.clear();
  }

  // Check key exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // Auth helpers
  static Future<void> saveAuthData({
    required String token,
    required String refreshToken,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    await setString('auth_token', token);
    await setString('auth_refresh_token', refreshToken);
    await setString('user_id', userId);
    await setString('user_name', userName);
    await setString('user_phone', userPhone);
    await setBool('is_logged_in', true);
  }

  static Future<void> clearAuthData() async {
    await remove('auth_token');
    await remove('auth_refresh_token');
    await remove('user_id');
    await remove('user_name');
    await remove('user_phone');
    await remove('is_logged_in');
    await remove('is_verified');
    await remove('driver_status');
  }

  static bool get isLoggedIn {
    return getBool('is_logged_in') ?? false;
  }

  static String? get token {
    return getString('auth_token');
  }

  static String? get userName {
    return getString('user_name');
  }

  static String? get userPhone {
    return getString('user_phone');
  }
}
