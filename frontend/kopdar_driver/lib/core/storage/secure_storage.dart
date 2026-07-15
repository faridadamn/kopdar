import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.keyToken, value: accessToken),
      _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> get accessToken =>
      _storage.read(key: AppConstants.keyToken);

  static Future<String?> get refreshToken =>
      _storage.read(key: AppConstants.keyRefreshToken);

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.keyToken),
      _storage.delete(key: AppConstants.keyRefreshToken),
    ]);
  }
}
