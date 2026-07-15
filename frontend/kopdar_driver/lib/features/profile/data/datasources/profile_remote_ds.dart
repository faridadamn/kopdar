import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';
import '../models/vehicle_model.dart';

/// Remote data source for profile API calls.
class ProfileRemoteDataSource {
  final ApiClient _api;

  ProfileRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  // ═══════════════════════════════════════
  //  PROFILE
  // ═══════════════════════════════════════

  /// Get current user profile.
  Future<ProfileModel> getProfile() async {
    final response = await _api.get('/api/v1/profile');
    return ProfileModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update profile (name, email, etc).
  Future<ProfileModel> updateProfile({
    String? name,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;

    final response = await _api.put('/api/v1/profile', data: data);
    return ProfileModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update profile photo.
  Future<String> updatePhoto(String filePath) async {
    final response = await _api.post(
      '/api/v1/profile/photo',
      data: FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
      }),
    );
    return response.data['data']['photo_url'] as String;
  }

  // ═══════════════════════════════════════
  //  LEVEL & REFERRAL
  // ═══════════════════════════════════════

  /// Get level & points info.
  Future<LevelInfo> getLevel() async {
    final response = await _api.get('/api/v1/profile/level');
    return LevelInfo.fromJson(response.data['data'] ?? response.data);
  }

  /// Get referral info.
  Future<ReferralInfo> getReferral() async {
    final response = await _api.get('/api/v1/profile/referral');
    return ReferralInfo.fromJson(response.data['data'] ?? response.data);
  }

  /// Apply a referral code.
  Future<bool> applyReferralCode(String code) async {
    final response = await _api.post(
      '/api/v1/profile/referral/apply',
      data: {'code': code},
    );
    return response.data['success'] as bool? ?? true;
  }

  // ═══════════════════════════════════════
  //  VEHICLES
  // ═══════════════════════════════════════

  /// Get all vehicles.
  Future<List<VehicleModel>> getVehicles() async {
    final response = await _api.get('/api/v1/profile/vehicles');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['vehicles'] ?? [];
    return (items as List)
        .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a new vehicle.
  Future<VehicleModel> addVehicle({
    required String type,
    required String brand,
    required String model,
    required int year,
    required String plateNumber,
    required String color,
    String? photoPath,
  }) async {
    final data = FormData.fromMap({
      'type': type,
      'brand': brand,
      'model': model,
      'year': year,
      'plate_number': plateNumber,
      'color': color,
      if (photoPath != null)
        'photo': await MultipartFile.fromFile(photoPath),
    });

    final response = await _api.post('/api/v1/profile/vehicles', data: data);
    return VehicleModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update an existing vehicle.
  Future<VehicleModel> updateVehicle(
    String id, {
    String? type,
    String? brand,
    String? model,
    int? year,
    String? plateNumber,
    String? color,
    String? photoPath,
  }) async {
    final data = <String, dynamic>{};
    if (type != null) data['type'] = type;
    if (brand != null) data['brand'] = brand;
    if (model != null) data['model'] = model;
    if (year != null) data['year'] = year;
    if (plateNumber != null) data['plate_number'] = plateNumber;
    if (color != null) data['color'] = color;
    if (photoPath != null) {
      data['photo'] = await MultipartFile.fromFile(photoPath);
    }

    final response = await _api.put(
      '/api/v1/profile/vehicles/$id',
      data: FormData.fromMap(data),
    );
    return VehicleModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Delete a vehicle.
  Future<bool> deleteVehicle(String id) async {
    final response = await _api.delete('/api/v1/profile/vehicles/$id');
    return response.data['success'] as bool? ?? true;
  }

  /// Set a vehicle as primary.
  Future<bool> setPrimaryVehicle(String id) async {
    final response =
        await _api.put('/api/v1/profile/vehicles/$id/primary');
    return response.data['success'] as bool? ?? true;
  }

  // ═══════════════════════════════════════
  //  DOCUMENTS
  // ═══════════════════════════════════════

  /// Get all documents.
  Future<List<DocumentModel>> getDocuments() async {
    final response = await _api.get('/api/v1/profile/documents');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['documents'] ?? [];
    return (items as List)
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upload a document.
  Future<DocumentModel> uploadDocument({
    required String type,
    required String filePath,
    String? fileName,
    DateTime? expiryDate,
  }) async {
    final response = await _api.post(
      '/api/v1/profile/documents',
      data: FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(filePath),
        if (fileName != null) 'file_name': fileName,
        if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
      }),
    );
    return DocumentModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Delete a document.
  Future<bool> deleteDocument(String id) async {
    final response = await _api.delete('/api/v1/profile/documents/$id');
    return response.data['success'] as bool? ?? true;
  }

  // ═══════════════════════════════════════
  //  SETTINGS
  // ═══════════════════════════════════════

  /// Get user settings.
  Future<SettingsModel> getSettings() async {
    final response = await _api.get('/api/v1/profile/settings');
    return SettingsModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Update user settings.
  Future<SettingsModel> updateSettings(Map<String, dynamic> updates) async {
    final response = await _api.put(
      '/api/v1/profile/settings',
      data: updates,
    );
    return SettingsModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Delete user account.
  Future<bool> deleteAccount() async {
    final response = await _api.delete('/api/v1/profile');
    return response.data['success'] as bool? ?? true;
  }
}
