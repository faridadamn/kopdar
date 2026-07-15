import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Level badge widget showing icon + level name.
class LevelBadge extends StatelessWidget {
  final String level;
  final double size;

  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: _bgColor.withOpacity(0.4), width: 2),
      ),
      child: Center(
        child: Text(
          _emoji,
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }

  String get _emoji {
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

  Color get _bgColor {
    switch (level.toLowerCase()) {
      case 'platinum':
        return AppColors.info;
      case 'gold':
        return AppColors.warning;
      case 'silver':
        return AppColors.gray500;
      default:
        return const Color(0xFFCD7F32);
    }
  }
}

/// Extended level badge with label.
class LevelBadgeWithLabel extends StatelessWidget {
  final String level;
  final String? label;
  final double badgeSize;

  const LevelBadgeWithLabel({
    super.key,
    required this.level,
    this.label,
    this.badgeSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LevelBadge(level: level, size: badgeSize),
        const SizedBox(height: 12),
        Text(
          label ?? _levelName,
          style: TextStyle(
            fontSize: badgeSize * 0.25,
            fontWeight: FontWeight.w800,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  String get _levelName {
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

  Color get _textColor {
    switch (level.toLowerCase()) {
      case 'platinum':
        return AppColors.info;
      case 'gold':
        return AppColors.warning;
      case 'silver':
        return AppColors.gray600;
      default:
        return const Color(0xFFCD7F32);
    }
  }
}
