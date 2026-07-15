import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Data for an expense category option.
class CategoryOption {
  final String name;
  final String emoji;

  const CategoryOption({required this.name, required this.emoji});
}

/// Available expense categories.
const List<CategoryOption> expenseCategories = [
  CategoryOption(name: 'Bensin', emoji: '⛽'),
  CategoryOption(name: 'Makan', emoji: '🍚'),
  CategoryOption(name: 'Angsuran', emoji: '🏍️'),
  CategoryOption(name: 'Servis', emoji: '🔧'),
  CategoryOption(name: 'Pulsa', emoji: '📱'),
  CategoryOption(name: 'Parkir', emoji: '🅿️'),
  CategoryOption(name: 'Kesehatan', emoji: '💊'),
  CategoryOption(name: 'Lainnya', emoji: '📦'),
];

/// 2x4 grid of expense category buttons.
class CategoryGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String>? onSelected;

  const CategoryGrid({
    super.key,
    this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: expenseCategories.length,
      itemBuilder: (context, index) {
        final cat = expenseCategories[index];
        final isSelected = selected == cat.name;
        return _CategoryItem(
          option: cat,
          isSelected: isSelected,
          onTap: () => onSelected?.call(cat.name),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryOption option;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CategoryItem({
    required this.option,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              option.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
