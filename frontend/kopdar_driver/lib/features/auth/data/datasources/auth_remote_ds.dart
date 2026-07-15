import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendOtp,
        data: {'phone': phoneNumber},
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal mengirim OTP. Silakan coba lagi.');
    }
  }

  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phone': phoneNumber,
          'otp': otpCode,
        },
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal verifikasi OTP. Silakan coba lagi.');
    }
  }

  /// Submit personal data (Step 1)
  Future<Map<String, dynamic>> submitPersonalData({
    required String name,
    required String nik,
    required String address,
    required String province,
    required String city,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerPersonal,
        data: {
          'name': name,
          'nik': nik,
          'address': address,
          'province': province,
          'city': city,
        },
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal menyimpan data. Silakan coba lagi.');
    }
  }

  /// Upload KTP photo
  Future<Map<String, dynamic>> uploadKtp(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'ktp_photo': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final response = await _apiClient.post(
        ApiEndpoints.uploadKtp,
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal upload foto KTP. Silakan coba lagi.');
    }
  }

  /// Upload selfie with KTP
  Future<Map<String, dynamic>> uploadSelfie(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final response = await _apiClient.post(
        ApiEndpoints.uploadSelfie,
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal upload selfie. Silakan coba lagi.');
    }
  }

  /// Submit vehicle data (Step 3)
  Future<Map<String, dynamic>> submitVehicleData({
    required String vehicleType,
    required String brand,
    required String model,
    required int year,
    required String plat,
    required String color,
    File? vehiclePhoto,
  }) async {
    try {
      final formData = FormData.fromMap({
        'vehicle_type': vehicleType,
        'brand': brand,
        'model': model,
        'year': year,
        'plat': plat,
        'color': color,
        if (vehiclePhoto != null)
          'vehicle_photo': await MultipartFile.fromFile(
            vehiclePhoto.path,
            filename: 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });
      final response = await _apiClient.post(
        ApiEndpoints.registerVehicle,
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal menyimpan data kendaraan. Silakan coba lagi.');
    }
  }

  /// Submit platform selection (Step 4)
  Future<Map<String, dynamic>> submitPlatforms({
    required List<String> platforms,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerPlatforms,
        data: {'platforms': platforms},
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal menyimpan data platform. Silakan coba lagi.');
    }
  }

  /// Submit bank info (Step 5)
  Future<Map<String, dynamic>> submitBankInfo({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerBank,
        data: {
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_name': accountName,
        },
      );
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal menyimpan data bank. Silakan coba lagi.');
    }
  }

  /// Submit full registration
  Future<Map<String, dynamic>> submitRegistration() async {
    try {
      final response = await _apiClient.post(ApiEndpoints.registerSubmit);
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal mengirim pendaftaran. Silakan coba lagi.');
    }
  }

  /// Check registration status
  Future<Map<String, dynamic>> checkRegistrationStatus() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.registerStatus);
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal memeriksa status. Silakan coba lagi.');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore logout errors, clear local data anyway
    }
  }
}
