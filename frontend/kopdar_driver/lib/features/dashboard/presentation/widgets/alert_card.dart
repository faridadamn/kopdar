import 'package:flutter/material.dart';

import 'package:kopdar_driver/config/theme.dart';

/// Conditional warning/info/danger alert card that can be dismissed.
class AlertCard extends StatelessWidget {
  final String message;
  final String type;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.message,
    this.type = 'warning',
    this.onDismiss,
    this.onTap,
  });

  Color get _backgroundColor {
    switch (type) {
      case 'danger':
        return AppColors.dangerLight;
      case 'info':
        return AppColors.blueLight;
      case 'warning':
      default:
        return AppColors.accentLight;
    }
  }

  Color get _borderColor {
    switch (type) {
      case 'danger':
        return AppColors.danger;
      case 'info':
        return AppColors.blue;
      case 'warning':
      default:
        return AppColors.warning;
    }
  }

  String get _icon {
    switch (type) {
      case 'danger':
        return '🚨';
      case 'info':
        return 'ℹ️';
      case 'warning':
      default:
        return '⚠️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.gray300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.close, color: AppColors.gray600),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(_icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray800,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
