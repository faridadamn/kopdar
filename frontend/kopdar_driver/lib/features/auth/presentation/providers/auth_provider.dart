import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../config/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/auth_remote_ds.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  pendingVerification,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRemoteDataSource _remoteDataSource;

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

  AuthProvider({AuthRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    if (!LocalStorage.isLoggedIn) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

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
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _setLoading();
    try {
      await _remoteDataSource.sendOtp(phone);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      return _setError(e.message);
    } catch (_) {
      return _setError('Gagal mengirim OTP. Silakan coba lagi.');
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _setLoading();
    try {
      final tokens = await _remoteDataSource.verifyOtp(
        phoneNumber: phone,
        otpCode: otp,
      );
      final accessToken = tokens['access_token'] as String?;
      final refreshToken = tokens['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw const ServerException('Token autentikasi tidak ditemukan.');
      }

      _userPhone = phone;
      _userId = phone;
      await LocalStorage.saveAuthData(
        token: accessToken,
        refreshToken: refreshToken,
        userId: _userId!,
        userName: _userName ?? '',
        userPhone: phone,
      );

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      return _setError(e.message);
    } catch (_) {
      return _setError('Kode OTP salah atau sudah kedaluwarsa.');
    }
  }

  Future<bool> submitDriverRegistration({
    required String fullName,
    required String nik,
    required DateTime dateOfBirth,
    required String address,
    required String city,
    required String province,
    required String vehicleType,
    required String vehiclePlate,
    required File ktpPhoto,
    required File selfiePhoto,
    required File stnkPhoto,
    String postalCode = '',
    String vehicleBrand = '',
    String vehicleModel = '',
    String vehicleColor = '',
    int? vehicleYear,
    String bankName = '',
    String bankAccountNumber = '',
    String bankAccountName = '',
    String emergencyContactName = '',
    String emergencyContactPhone = '',
    List<String> platforms = const [],
  }) async {
    _setLoading();
    try {
      await _remoteDataSource.submitDriverRegistration(
        fullName: fullName,
        nik: nik,
        dateOfBirth: _formatDate(dateOfBirth),
        address: address,
        city: city,
        province: province,
        postalCode: postalCode,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
        vehicleBrand: vehicleBrand,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        vehicleYear: vehicleYear,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        platforms: platforms,
        ktpPhoto: ktpPhoto,
        selfiePhoto: selfiePhoto,
        stnkPhoto: stnkPhoto,
      );

      _userName = fullName;
      _driverStatus = 'pending';
      await LocalStorage.setString(AppConstants.keyUserName, fullName);
      await LocalStorage.setString(AppConstants.keyDriverStatus, 'pending');
      await LocalStorage.setBool(AppConstants.keyIsVerified, false);
      _status = AuthStatus.pendingVerification;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      return _setError(e.message);
    } catch (_) {
      return _setError('Gagal mengirim pendaftaran. Silakan coba lagi.');
    }
  }

  Future<void> checkVerificationStatus() async {
    try {
      final result = await _remoteDataSource.checkRegistrationStatus();
      final verificationStatus = result['verification_status'] as String?;
      if (verificationStatus == null) return;

      _driverStatus = verificationStatus;
      await LocalStorage.setString(
        AppConstants.keyDriverStatus,
        verificationStatus,
      );

      switch (verificationStatus) {
        case 'approved':
        case 'verified':
          await LocalStorage.setBool(AppConstants.keyIsVerified, true);
          _status = AuthStatus.authenticated;
          break;
        case 'pending':
          _status = AuthStatus.pendingVerification;
          break;
        case 'rejected':
          _status = AuthStatus.error;
          _errorMessage = (result['rejection_reason'] as String?) ??
              'Pendaftaran ditolak. Silakan periksa kembali data Anda.';
          break;
        default:
          _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    } on NotFoundException {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } on UnauthorizedException {
      await _clearSession();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    await LocalStorage.clearAuthData();
    _status = AuthStatus.unauthenticated;
    _userId = null;
    _userName = null;
    _userPhone = null;
    _driverStatus = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  bool _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
