import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Widget displaying coverage details with checkmark bullets.
class CoverageList extends StatelessWidget {
  final List<String> items;
  final String title;
  final bool isExclusion;

  const CoverageList({
    super.key,
    required this.items,
    required this.title,
    this.isExclusion = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: isExclusion
                        ? AppColors.danger.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isExclusion
                        ? Icons.close_rounded
                        : Icons.check_rounded,
                    size: 14,
                    color:
                        isExclusion ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
