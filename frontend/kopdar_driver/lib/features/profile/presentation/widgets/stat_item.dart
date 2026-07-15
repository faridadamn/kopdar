import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Stat item widget: icon + value + label in a column.
class StatItem extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String value;
  final String label;

  const StatItem({
    super.key,
    this.icon,
    this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (emoji != null)
          Text(emoji!, style: const TextStyle(fontSize: 20))
        else if (icon != null)
          Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
