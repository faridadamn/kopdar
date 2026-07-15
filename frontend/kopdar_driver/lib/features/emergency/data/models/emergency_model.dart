/// Data models for the Emergency / SOS feature.

class EmergencyModel {
  final String id;
  final String driverId;
  final String type; // 'accident', 'breakdown', 'medical', 'crime', 'other'
  final String status; // 'active', 'responding', 'resolved'
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final List<EmergencyContactModel> notifiedContacts;
  final List<NearbyDriverModel> responders;

  EmergencyModel({
    required this.id,
    required this.driverId,
    required this.type,
    required this.status,
    this.description,
    this.latitude,
    this.longitude,
    this.address,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.notifiedContacts = const [],
    this.responders = const [],
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      notifiedContacts: (json['notified_contacts'] as List<dynamic>?)
              ?.map((e) =>
                  EmergencyContactModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      responders: (json['responders'] as List<dynamic>?)
              ?.map((e) =>
                  NearbyDriverModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driver_id': driverId,
        'type': type,
        'status': status,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'created_at': createdAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        'resolved_by': resolvedBy,
      };

  bool get isActive => status == 'active';
  bool get isResponding => status == 'responding';
  bool get isResolved => status == 'resolved';

  String get typeLabel {
    switch (type) {
      case 'accident':
        return 'Kecelakaan';
      case 'breakdown':
        return 'Mogok';
      case 'medical':
        return 'Medis';
      case 'crime':
        return 'Kriminal';
      default:
        return 'Lainnya';
    }
  }
}

class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relation; // 'keluarga', 'pasangan', 'teman', 'lainnya'
  final bool isPrimary;
  final bool notified;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relation,
    this.isPrimary = false,
    this.notified = false,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      relation: json['relation'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      notified: json['notified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'relation': relation,
        'is_primary': isPrimary,
        'notified': notified,
      };

  String get relationLabel {
    switch (relation) {
      case 'keluarga':
        return 'Keluarga';
      case 'pasangan':
        return 'Pasangan';
      case 'teman':
        return 'Teman';
      default:
        return 'Lainnya';
    }
  }
}

class DriverMedicalModel {
  final String? id;
  final String? bloodType; // A, B, AB, O, A+, A-, B+, B-, AB+, AB-, O+, O-
  final List<String> allergies;
  final List<String> conditions; // chronic conditions
  final List<String> medications;
  final String? emergencyNotes;
  final String? hospitalPreference;

  DriverMedicalModel({
    this.id,
    this.bloodType,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
    this.emergencyNotes,
    this.hospitalPreference,
  });

  factory DriverMedicalModel.fromJson(Map<String, dynamic> json) {
    return DriverMedicalModel(
      id: json['id'] as String?,
      bloodType: json['blood_type'] as String?,
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      medications: (json['medications'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      emergencyNotes: json['emergency_notes'] as String?,
      hospitalPreference: json['hospital_preference'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'blood_type': bloodType,
        'allergies': allergies,
        'conditions': conditions,
        'medications': medications,
        'emergency_notes': emergencyNotes,
        'hospital_preference': hospitalPreference,
      };

  bool get hasData =>
      bloodType != null ||
      allergies.isNotEmpty ||
      conditions.isNotEmpty ||
      medications.isNotEmpty;
}

class NearbyDriverModel {
  final String driverId;
  final String name;
  final String? avatarUrl;
  final double distanceKm;
  final int etaMinutes;
  final bool isResponding;
  final String? phoneNumber;

  NearbyDriverModel({
    required this.driverId,
    required this.name,
    this.avatarUrl,
    required this.distanceKm,
    required this.etaMinutes,
    this.isResponding = false,
    this.phoneNumber,
  });

  factory NearbyDriverModel.fromJson(Map<String, dynamic> json) {
    return NearbyDriverModel(
      driverId: json['driver_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      distanceKm: (json['distance_km'] as num).toDouble(),
      etaMinutes: json['eta_minutes'] as int,
      isResponding: json['is_responding'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'driver_id': driverId,
        'name': name,
        'avatar_url': avatarUrl,
        'distance_km': distanceKm,
        'eta_minutes': etaMinutes,
        'is_responding': isResponding,
        'phone_number': phoneNumber,
      };
}
