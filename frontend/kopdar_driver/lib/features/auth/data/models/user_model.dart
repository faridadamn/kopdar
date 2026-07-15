class UserModel {
  final String id;
  final String phone;
  final String? name;
  final String? nik;
  final String? address;
  final String? province;
  final String? city;
  final String? ktpPhotoUrl;
  final String? selfiePhotoUrl;
  final String? vehicleType;
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlat;
  final String? vehicleColor;
  final String? vehiclePhotoUrl;
  final List<String> platforms;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String status; // 'pending', 'verified', 'rejected', 'suspended'
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.nik,
    this.address,
    this.province,
    this.city,
    this.ktpPhotoUrl,
    this.selfiePhotoUrl,
    this.vehicleType,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlat,
    this.vehicleColor,
    this.vehiclePhotoUrl,
    this.platforms = const [],
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      nik: json['nik'] as String?,
      address: json['address'] as String?,
      province: json['province'] as String?,
      city: json['city'] as String?,
      ktpPhotoUrl: json['ktp_photo_url'] as String?,
      selfiePhotoUrl: json['selfie_photo_url'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      vehicleBrand: json['vehicle_brand'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleYear: json['vehicle_year'] as int?,
      vehiclePlat: json['vehicle_plat'] as String?,
      vehicleColor: json['vehicle_color'] as String?,
      vehiclePhotoUrl: json['vehicle_photo_url'] as String?,
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'nik': nik,
      'address': address,
      'province': province,
      'city': city,
      'ktp_photo_url': ktpPhotoUrl,
      'selfie_photo_url': selfiePhotoUrl,
      'vehicle_type': vehicleType,
      'vehicle_brand': vehicleBrand,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'vehicle_plat': vehiclePlat,
      'vehicle_color': vehicleColor,
      'vehicle_photo_url': vehiclePhotoUrl,
      'platforms': platforms,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? nik,
    String? address,
    String? province,
    String? city,
    String? ktpPhotoUrl,
    String? selfiePhotoUrl,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    String? vehiclePlat,
    String? vehicleColor,
    String? vehiclePhotoUrl,
    List<String>? platforms,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      nik: nik ?? this.nik,
      address: address ?? this.address,
      province: province ?? this.province,
      city: city ?? this.city,
      ktpPhotoUrl: ktpPhotoUrl ?? this.ktpPhotoUrl,
      selfiePhotoUrl: selfiePhotoUrl ?? this.selfiePhotoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehiclePlat: vehiclePlat ?? this.vehiclePlat,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      platforms: platforms ?? this.platforms,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}
