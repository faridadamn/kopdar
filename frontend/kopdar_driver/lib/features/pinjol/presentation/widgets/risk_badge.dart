import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Risk level badge with colored container.
class RiskBadge extends StatelessWidget {
  final String riskLevel; // safe, warning, danger
  final bool compact;

  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.compact = false,
  });

  Color get _backgroundColor {
    switch (riskLevel) {
      case 'safe':
        return AppColors.success.withOpacity(0.12);
      case 'warning':
        return AppColors.warning.withOpacity(0.12);
      case 'danger':
        return AppColors.danger.withOpacity(0.12);
      default:
        return AppColors.gray200;
    }
  }

  Color get _textColor {
    switch (riskLevel) {
      case 'safe':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.danger;
      default:
        return AppColors.gray600;
    }
  }

  String get _emoji {
    switch (riskLevel) {
      case 'safe':
        return '🟢';
      case 'warning':
        return '🟡';
      case 'danger':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get _label {
    switch (riskLevel) {
      case 'safe':
        return 'Aman';
      case 'warning':
        return 'Waspada';
      case 'danger':
        return 'Berisiko';
      default:
        return riskLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji, style: TextStyle(fontSize: compact ? 10 : 12)),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
