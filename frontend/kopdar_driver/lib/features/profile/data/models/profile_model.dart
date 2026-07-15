/// Profile feature data models.

class ProfileModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? photoUrl;
  final String memberId;
  final String level;
  final int points;
  final int totalOrders;
  final int activeDays;
  final double rating;
  final DateTime memberSince;
  final LevelInfo? levelInfo;
  final ReferralInfo? referralInfo;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.photoUrl,
    required this.memberId,
    required this.level,
    required this.points,
    required this.totalOrders,
    required this.activeDays,
    required this.rating,
    required this.memberSince,
    this.levelInfo,
    this.referralInfo,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      memberId: json['member_id'] as String? ?? '',
      level: json['level'] as String? ?? 'bronze',
      points: json['points'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      activeDays: json['active_days'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      memberSince: json['member_since'] != null
          ? DateTime.parse(json['member_since'] as String)
          : DateTime.now(),
      levelInfo: json['level_info'] != null
          ? LevelInfo.fromJson(json['level_info'] as Map<String, dynamic>)
          : null,
      referralInfo: json['referral_info'] != null
          ? ReferralInfo.fromJson(
              json['referral_info'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'photo_url': photoUrl,
        'member_id': memberId,
        'level': level,
        'points': points,
        'total_orders': totalOrders,
        'active_days': activeDays,
        'rating': rating,
        'member_since': memberSince.toIso8601String(),
      };

  /// Level display name in Bahasa.
  String get levelLabel {
    switch (level.toLowerCase()) {
      case 'platinum':
        return 'Platinum';
      case 'gold':
        return 'Emas';
      case 'silver':
        return 'Perak';
      default:
        return 'Perunggu';
    }
  }

  /// Level emoji badge.
  String get levelEmoji {
    switch (level.toLowerCase()) {
      case 'platinum':
        return '💎';
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      default:
        return '🥉';
    }
  }
}

class LevelInfo {
  final String currentLevel;
  final int currentPoints;
  final int nextLevelPoints;
  final String nextLevel;
  final double progress;
  final List<LevelBenefit> benefits;
  final List<PointsHistory> pointsHistory;

  const LevelInfo({
    required this.currentLevel,
    required this.currentPoints,
    required this.nextLevelPoints,
    required this.nextLevel,
    required this.progress,
    required this.benefits,
    required this.pointsHistory,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      currentLevel: json['current_level'] as String? ?? 'bronze',
      currentPoints: json['current_points'] as int? ?? 0,
      nextLevelPoints: json['next_level_points'] as int? ?? 100,
      nextLevel: json['next_level'] as String? ?? 'silver',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map(
                  (e) => LevelBenefit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pointsHistory: (json['points_history'] as List<dynamic>?)
              ?.map(
                  (e) => PointsHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class LevelBenefit {
  final String icon;
  final String title;
  final String description;
  final bool unlocked;

  const LevelBenefit({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  factory LevelBenefit.fromJson(Map<String, dynamic> json) {
    return LevelBenefit(
      icon: json['icon'] as String? ?? '🎁',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }
}

class PointsHistory {
  final String id;
  final String action;
  final int points;
  final String type; // 'earn' or 'spend'
  final DateTime createdAt;

  const PointsHistory({
    required this.id,
    required this.action,
    required this.points,
    required this.type,
    required this.createdAt,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) {
    return PointsHistory(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      type: json['type'] as String? ?? 'earn',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class ReferralInfo {
  final String code;
  final int totalReferrals;
  final int totalBonus;
  final List<ReferralEntry> referrals;

  const ReferralInfo({
    required this.code,
    required this.totalReferrals,
    required this.totalBonus,
    required this.referrals,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      code: json['code'] as String? ?? '',
      totalReferrals: json['total_referrals'] as int? ?? 0,
      totalBonus: json['total_bonus'] as int? ?? 0,
      referrals: (json['referrals'] as List<dynamic>?)
              ?.map(
                  (e) => ReferralEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ReferralEntry {
  final String id;
  final String name;
  final String status; // 'pending', 'completed'
  final int bonus;
  final DateTime createdAt;

  const ReferralEntry({
    required this.id,
    required this.name,
    required this.status,
    required this.bonus,
    required this.createdAt,
  });

  factory ReferralEntry.fromJson(Map<String, dynamic> json) {
    return ReferralEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      bonus: json['bonus'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
}

class SettingsModel {
  final String language;
  final String timezone;
  final bool autoSave;
  final bool notifOrder;
  final bool notifPromo;
  final bool notifCommunity;
  final bool notifSOS;
  final bool biometricEnabled;
  final String appVersion;

  const SettingsModel({
    required this.language,
    required this.timezone,
    required this.autoSave,
    required this.notifOrder,
    required this.notifPromo,
    required this.notifCommunity,
    required this.notifSOS,
    required this.biometricEnabled,
    required this.appVersion,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      language: json['language'] as String? ?? 'id',
      timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
      autoSave: json['auto_save'] as bool? ?? false,
      notifOrder: json['notif_order'] as bool? ?? true,
      notifPromo: json['notif_promo'] as bool? ?? true,
      notifCommunity: json['notif_community'] as bool? ?? true,
      notifSOS: json['notif_sos'] as bool? ?? true,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      appVersion: json['app_version'] as String? ?? '1.0.0',
    );
  }

  SettingsModel copyWith({
    String? language,
    String? timezone,
    bool? autoSave,
    bool? notifOrder,
    bool? notifPromo,
    bool? notifCommunity,
    bool? notifSOS,
    bool? biometricEnabled,
  }) {
    return SettingsModel(
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      autoSave: autoSave ?? this.autoSave,
      notifOrder: notifOrder ?? this.notifOrder,
      notifPromo: notifPromo ?? this.notifPromo,
      notifCommunity: notifCommunity ?? this.notifCommunity,
      notifSOS: notifSOS ?? this.notifSOS,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      appVersion: appVersion,
    );
  }
}
