/// Model for an insurance product in the catalog.
class InsuranceProduct {
  final String id;
  final String name;
  final String description;
  final String productType; // accident, inpatient, vehicle, family
  final String icon;
  final Map<String, dynamic> coverageDetails;
  final double priceMember;
  final double priceNonMember;
  final String partnerName;
  final bool hasActivePolicy;

  const InsuranceProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.productType,
    required this.icon,
    required this.coverageDetails,
    required this.priceMember,
    required this.priceNonMember,
    required this.partnerName,
    required this.hasActivePolicy,
  });

  factory InsuranceProduct.fromJson(Map<String, dynamic> json) {
    return InsuranceProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      productType: json['product_type'] as String? ?? 'accident',
      icon: json['icon'] as String? ?? '🛡️',
      coverageDetails: json['coverage_details'] as Map<String, dynamic>? ?? {},
      priceMember: (json['price_member'] as num).toDouble(),
      priceNonMember: (json['price_non_member'] as num).toDouble(),
      partnerName: json['partner_name'] as String? ?? '',
      hasActivePolicy: json['has_active_policy'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'product_type': productType,
      'icon': icon,
      'coverage_details': coverageDetails,
      'price_member': priceMember,
      'price_non_member': priceNonMember,
      'partner_name': partnerName,
      'has_active_policy': hasActivePolicy,
    };
  }

  /// Human-readable product type label.
  String get typeLabel {
    switch (productType) {
      case 'accident':
        return 'Kecelakaan Kerja';
      case 'inpatient':
        return 'Rawat Inap';
      case 'vehicle':
        return 'Kendaraan';
      case 'family':
        return 'Keluarga';
      default:
        return productType;
    }
  }

  /// Coverage items extracted from coverage_details.
  List<String> get coverageItems {
    final items = coverageDetails['coverage'] as List<dynamic>?;
    return items?.map((e) => e.toString()).toList() ?? [];
  }

  /// Exclusion items extracted from coverage_details.
  List<String> get exclusionItems {
    final items = coverageDetails['exclusions'] as List<dynamic>?;
    return items?.map((e) => e.toString()).toList() ?? [];
  }

  /// Discount percentage (member vs non-member).
  int get discountPercent {
    if (priceNonMember <= 0) return 0;
    return ((1 - priceMember / priceNonMember) * 100).round();
  }
}

/// Model for an active insurance policy.
class InsurancePolicy {
  final String id;
  final String productId;
  final String productName;
  final String policyNumber;
  final double premium;
  final String paymentMethod;
  final String status; // active, expired, cancelled
  final DateTime startDate;
  final DateTime endDate;
  final int daysUntilExpiry;

  const InsurancePolicy({
    required this.id,
    required this.productId,
    required this.productName,
    required this.policyNumber,
    required this.premium,
    required this.paymentMethod,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.daysUntilExpiry,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      policyNumber: json['policy_number'] as String? ?? '',
      premium: (json['premium'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      daysUntilExpiry: (json['days_until_expiry'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'policy_number': policyNumber,
      'premium': premium,
      'payment_method': paymentMethod,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'days_until_expiry': daysUntilExpiry,
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  /// Whether the policy is expiring within 30 days.
  bool get isExpiringSoon => isActive && daysUntilExpiry <= 30;

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'expired':
        return 'Kedaluwarsa';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

/// Model for an insurance claim.
class InsuranceClaim {
  final String id;
  final String policyId;
  final String policyName;
  final String claimType;
  final String description;
  final List<String> evidenceUrls;
  final String status; // pending, approved, rejected, reimbursed
  final String? adminNotes;
  final DateTime createdAt;

  const InsuranceClaim({
    required this.id,
    required this.policyId,
    required this.policyName,
    required this.claimType,
    required this.description,
    required this.evidenceUrls,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      id: json['id'] as String,
      policyId: json['policy_id'] as String,
      policyName: json['policy_name'] as String? ?? '',
      claimType: json['claim_type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      evidenceUrls: (json['evidence_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'policy_id': policyId,
      'policy_name': policyName,
      'claim_type': claimType,
      'description': description,
      'evidence_urls': evidenceUrls,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isReimbursed => status == 'reimbursed';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'reimbursed':
        return 'Dibayar';
      default:
        return status;
    }
  }

  String get claimTypeLabel {
    switch (claimType) {
      case 'accident':
        return 'Kecelakaan';
      case 'inpatient':
        return 'Rawat Inap';
      case 'vehicle':
        return 'Kendaraan';
      default:
        return claimType;
    }
  }
}
