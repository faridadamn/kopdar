/// Rewards & loyalty data models.

class RewardModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int pointsCost;
  final String category; // 'voucher', 'saldo', 'merchandise', 'service'
  final int stock;
  final bool isAvailable;
  final String? imageUrl;

  const RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsCost,
    required this.category,
    required this.stock,
    required this.isAvailable,
    this.imageUrl,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎁',
      pointsCost: json['points_cost'] as int? ?? 0,
      category: json['category'] as String? ?? 'voucher',
      stock: json['stock'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final double progress; // 0.0 to 1.0
  final int? rewardPoints;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.progress,
    this.rewardPoints,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏅',
      unlocked: json['unlocked'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      rewardPoints: json['reward_points'] as int?,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String? photoUrl;
  final int points;
  final String level;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    this.photoUrl,
    required this.points,
    required this.level,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      points: json['points'] as int? ?? 0,
      level: json['level'] as String? ?? 'bronze',
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }

  String get levelEmoji {
    switch (level) {
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
