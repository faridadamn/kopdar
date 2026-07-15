import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Map<String, dynamic> _unwrap(Response response) {
    final envelope = response.data;
    if (envelope is! Map<String, dynamic>) {
      throw const ServerException('Format response server tidak valid.');
    }
    final data = envelope['data'];
    if (data == null) return <String, dynamic>{};
    if (data is Map<String, dynamic>) return data;
    throw const ServerException('Payload response server tidak valid.');
  }

  Future<void> sendOtp(String phoneNumber) async {
    await _apiClient.post(
      ApiEndpoints.sendOtp,
      data: {'phone': phoneNumber},
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {'phone': phoneNumber, 'otp': otpCode},
    );
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'phone': phoneNumber, 'otp': otpCode},
    );
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> submitDriverRegistration({
    required String fullName,
    required String nik,
    required String dateOfBirth,
    required String address,
    required String city,
    required String province,
    required String vehicleType,
    required String vehiclePlate,
    required File ktpPhoto,
    required File selfiePhoto,
    required File stnkPhoto,
    String postalCode = '',
    int? vehicleYear,
    String emergencyContactName = '',
    String emergencyContactPhone = '',
    List<String> platforms = const [],
  }) async {
    final formData = FormData.fromMap({
      'full_name': fullName,
      'nik': nik,
      'date_of_birth': dateOfBirth,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      if (vehicleYear != null) 'vehicle_year': vehicleYear,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'platforms': jsonEncode(platforms),
      'ktp_photo': await MultipartFile.fromFile(
        ktpPhoto.path,
        filename: ktpPhoto.uri.pathSegments.last,
      ),
      'selfie_photo': await MultipartFile.fromFile(
        selfiePhoto.path,
        filename: selfiePhoto.uri.pathSegments.last,
      ),
      'stnk_photo': await MultipartFile.fromFile(
        stnkPhoto.path,
        filename: stnkPhoto.uri.pathSegments.last,
      ),
    });

    final response = await _apiClient.post(
      ApiEndpoints.registerDriver,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> checkRegistrationStatus() async {
    final response = await _apiClient.get(ApiEndpoints.registerStatus);
    return _unwrap(response);
  }

  Future<void> logout() async {
    final refreshToken = await SecureStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return;

    await _apiClient.delete(
      ApiEndpoints.logout,
      data: {'refresh_token': refreshToken},
    );
  }
}