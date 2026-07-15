import 'package:flutter/material.dart';
import '../../../core/storage/local_storage.dart';
import '../../../config/constants.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  pendingVerification,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userId;
  String? _userName;
  String? _userPhone;
  String? _driverStatus;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  String? get driverStatus => _driverStatus;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isPending => _status == AuthStatus.pendingVerification;

  AuthProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final isLoggedIn = LocalStorage.isLoggedIn;
    if (isLoggedIn) {
      _userId = LocalStorage.getString(AppConstants.keyUserId);
      _userName = LocalStorage.getString(AppConstants.keyUserName);
      _userPhone = LocalStorage.getString(AppConstants.keyUserPhone);
      _driverStatus = LocalStorage.getString(AppConstants.keyDriverStatus);

      if (_driverStatus == 'pending') {
        _status = AuthStatus.pendingVerification;
      } else if (LocalStorage.getBool(AppConstants.keyIsVerified) == true) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Gagal mengirim OTP. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Simulate success
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _userPhone = phone;

      await LocalStorage.saveAuthData(
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token',
        userId: _userId!,
        userName: '',
        userPhone: phone,
      );

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Kode OTP salah atau sudah expired.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitRegistration({
    required String name,
    required String nik,
    required String address,
    required String province,
    required String city,
    required String vehicleType,
    required String vehicleBrand,
    required String vehicleModel,
    required int vehicleYear,
    required String vehiclePlat,
    required String vehicleColor,
    required List<String> platforms,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      _userName = name;
      _driverStatus = 'pending';

      await LocalStorage.setString(AppConstants.keyUserName, name);
      await LocalStorage.setString(AppConstants.keyDriverStatus, 'pending');

      _status = AuthStatus.pendingVerification;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Gagal mengirim pendaftaran. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  Future<void> checkVerificationStatus() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In real app, check API
      // For demo, stay pending
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> logout() async {
    await LocalStorage.clearAuthData();
    _status = AuthStatus.unauthenticated;
    _userId = null;
    _userName = null;
    _userPhone = null;
    _driverStatus = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
