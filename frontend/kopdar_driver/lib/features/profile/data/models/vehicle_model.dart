/// Vehicle and document models for the Profile feature.

class VehicleModel {
  final String id;
  final String type; // 'Motor' or 'Mobil'
  final String brand;
  final String model;
  final int year;
  final String plateNumber;
  final String color;
  final String? photoUrl;
  final bool isPrimary;
  final DateTime createdAt;

  const VehicleModel({
    required this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.color,
    this.photoUrl,
    required this.isPrimary,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'Motor',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      plateNumber: json['plate_number'] as String? ?? '',
      color: json['color'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'brand': brand,
        'model': model,
        'year': year,
        'plate_number': plateNumber,
        'color': color,
        'is_primary': isPrimary,
      };

  String get typeEmoji => type == 'Mobil' ? '🚗' : '🏍️';

  String get displayName => '$brand $model ($year)';

  String get plateFormatted => plateNumber.toUpperCase();
}

class DocumentModel {
  final String id;
  final String type; // 'sim', 'stnk', 'skck', 'ktp'
  final String? fileUrl;
  final String? fileName;
  final DateTime? expiryDate;
  final String status; // 'pending', 'verified', 'expired', 'rejected'
  final DateTime uploadedAt;

  const DocumentModel({
    required this.id,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.expiryDate,
    required this.status,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'expiry_date': expiryDate?.toIso8601String(),
      };

  String get typeLabel {
    switch (type) {
      case 'sim':
        return 'SIM';
      case 'stnk':
        return 'STNK';
      case 'skck':
        return 'SKCK';
      case 'ktp':
        return 'KTP';
      default:
        return type.toUpperCase();
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'sim':
        return '🪪';
      case 'stnk':
        return '📋';
      case 'skck':
        return '📜';
      case 'ktp':
        return '🆔';
      default:
        return '📄';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'expired':
        return 'Kedaluwarsa';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Verifikasi';
    }
  }

  bool get isVerified => status == 'verified';
  bool get isExpired => status == 'expired';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return daysLeft <= 30 && daysLeft > 0;
  }
}
