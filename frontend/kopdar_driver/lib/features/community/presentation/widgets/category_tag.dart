import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Category tag chip for posts.
/// Color mapping: tips=green, question=blue, complaint=red, info=gray, advocacy=purple
class CategoryTag extends StatelessWidget {
  final String category;
  final bool compact;

  const CategoryTag({
    super.key,
    required this.category,
    this.compact = false,
  });

  static const Map<String, _CategoryConfig> _configs = {
    'tips': _CategoryConfig(
      label: 'Tips',
      color: AppColors.success,
      bgColor: Color(0xFFE8F5E9),
      icon: Icons.lightbulb_outline,
    ),
    'question': _CategoryConfig(
      label: 'Pertanyaan',
      color: AppColors.blue,
      bgColor: AppColors.blueLight,
      icon: Icons.help_outline,
    ),
    'complaint': _CategoryConfig(
      label: 'Keluhan',
      color: AppColors.danger,
      bgColor: AppColors.dangerLight,
      icon: Icons.report_problem_outlined,
    ),
    'info': _CategoryConfig(
      label: 'Info Zona',
      color: AppColors.gray600,
      bgColor: AppColors.gray100,
      icon: Icons.info_outline,
    ),
    'advocacy': _CategoryConfig(
      label: 'Advokasi',
      color: Color(0xFF7B1FA2),
      bgColor: Color(0xFFF3E5F5),
      icon: Icons.campaign_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _configs[category] ?? _configs['info']!;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          config.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: config.color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryConfig {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _CategoryConfig({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}
