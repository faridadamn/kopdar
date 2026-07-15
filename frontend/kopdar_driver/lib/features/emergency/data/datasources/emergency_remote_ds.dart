import '../../../../core/network/api_client.dart';
import '../models/emergency_model.dart';

/// Remote data source for emergency / SOS API calls.
class EmergencyRemoteDataSource {
  final ApiClient _api;

  EmergencyRemoteDataSource({ApiClient? api}) : _api = api ?? ApiClient();

  // ───────────────────── SOS ─────────────────────

  /// Trigger a new SOS emergency.
  Future<EmergencyModel> triggerSOS({
    required String type,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final response = await _api.post(
      '/api/v1/emergency/sos',
      data: {
        'type': type,
        if (description != null) 'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      },
    );
    return EmergencyModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Resolve an active SOS emergency.
  Future<EmergencyModel> resolveSOS(String emergencyId) async {
    final response = await _api.post(
      '/api/v1/emergency/sos/$emergencyId/resolve',
    );
    return EmergencyModel.fromJson(response.data['data'] ?? response.data);
  }

  /// Get current active SOS (if any).
  Future<EmergencyModel?> getActiveSOS() async {
    try {
      final response = await _api.get('/api/v1/emergency/sos/active');
      final data = response.data['data'] ?? response.data;
      if (data == null) return null;
      return EmergencyModel.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// List emergency history.
  Future<List<EmergencyModel>> listEmergencies({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;

    final response = await _api.get(
      '/api/v1/emergency/history',
      queryParameters: queryParams,
    );

    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) => EmergencyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['emergencies'] ?? [];
    return (items as List)
        .map((e) => EmergencyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get single emergency detail.
  Future<EmergencyModel> getEmergency(String id) async {
    final response = await _api.get('/api/v1/emergency/$id');
    return EmergencyModel.fromJson(response.data['data'] ?? response.data);
  }

  // ───────────────────── Contacts ─────────────────────

  /// List emergency contacts.
  Future<List<EmergencyContactModel>> listContacts() async {
    final response = await _api.get('/api/v1/emergency/contacts');
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) =>
              EmergencyContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['contacts'] ?? [];
    return (items as List)
        .map((e) =>
            EmergencyContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add an emergency contact.
  Future<EmergencyContactModel> addContact({
    required String name,
    required String phoneNumber,
    required String relation,
    bool isPrimary = false,
  }) async {
    final response = await _api.post(
      '/api/v1/emergency/contacts',
      data: {
        'name': name,
        'phone_number': phoneNumber,
        'relation': relation,
        'is_primary': isPrimary,
      },
    );
    return EmergencyContactModel.fromJson(
        response.data['data'] ?? response.data);
  }

  /// Update an emergency contact.
  Future<EmergencyContactModel> updateContact(
    String id, {
    String? name,
    String? phoneNumber,
    String? relation,
    bool? isPrimary,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (relation != null) data['relation'] = relation;
    if (isPrimary != null) data['is_primary'] = isPrimary;

    final response = await _api.put(
      '/api/v1/emergency/contacts/$id',
      data: data,
    );
    return EmergencyContactModel.fromJson(
        response.data['data'] ?? response.data);
  }

  /// Delete an emergency contact.
  Future<void> deleteContact(String id) async {
    await _api.delete('/api/v1/emergency/contacts/$id');
  }

  // ───────────────────── Medical ─────────────────────

  /// Get driver medical info.
  Future<DriverMedicalModel?> getMedicalInfo() async {
    try {
      final response = await _api.get('/api/v1/emergency/medical');
      final data = response.data['data'] ?? response.data;
      if (data == null) return null;
      return DriverMedicalModel.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Create or update driver medical info.
  Future<DriverMedicalModel> saveMedicalInfo({
    String? bloodType,
    List<String>? allergies,
    List<String>? conditions,
    List<String>? medications,
    String? emergencyNotes,
    String? hospitalPreference,
  }) async {
    final data = <String, dynamic>{};
    if (bloodType != null) data['blood_type'] = bloodType;
    if (allergies != null) data['allergies'] = allergies;
    if (conditions != null) data['conditions'] = conditions;
    if (medications != null) data['medications'] = medications;
    if (emergencyNotes != null) data['emergency_notes'] = emergencyNotes;
    if (hospitalPreference != null) {
      data['hospital_preference'] = hospitalPreference;
    }

    final response = await _api.put(
      '/api/v1/emergency/medical',
      data: data,
    );
    return DriverMedicalModel.fromJson(
        response.data['data'] ?? response.data);
  }

  // ───────────────────── Nearby ─────────────────────

  /// Get nearby drivers who can respond to an emergency.
  Future<List<NearbyDriverModel>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final response = await _api.get(
      '/api/v1/emergency/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      },
    );

    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((e) =>
              NearbyDriverModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = data['items'] ?? data['drivers'] ?? [];
    return (items as List)
        .map((e) =>
            NearbyDriverModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
