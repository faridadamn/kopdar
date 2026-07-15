import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  static String? getString(String key) => _prefs.getString(key);

  static Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  static int? getInt(String key) => _prefs.getInt(key);

  static Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  static bool? getBool(String key) => _prefs.getBool(key);

  static Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);
  static double? getDouble(String key) => _prefs.getDouble(key);

  static Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  static List<String>? getStringList(String key) => _prefs.getStringList(key);

  static Future<bool> remove(String key) => _prefs.remove(key);
  static Future<bool> clear() => _prefs.clear();
  static bool containsKey(String key) => _prefs.containsKey(key);

  static Future<void> saveAuthData({
    required String token,
    required String refreshToken,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    await SecureStorage.saveTokens(
      accessToken: token,
      refreshToken: refreshToken,
    );
    await Future.wait([
      setString('user_id', userId),
      setString('user_name', userName),
      setString('user_phone', userPhone),
      setBool('is_logged_in', true),
    ]);

    // Remove credentials written by older builds.
    await Future.wait([
      remove('auth_token'),
      remove('auth_refresh_token'),
    ]);
  }

  static Future<void> clearAuthData() async {
    await SecureStorage.clearTokens();
    await Future.wait([
      remove('auth_token'),
      remove('auth_refresh_token'),
      remove('user_id'),
      remove('user_name'),
      remove('user_phone'),
      remove('is_logged_in'),
      remove('is_verified'),
      remove('driver_status'),
    ]);
  }

  static bool get isLoggedIn => getBool('is_logged_in') ?? false;
  static String? get userName => getString('user_name');
  static String? get userPhone => getString('user_phone');
}