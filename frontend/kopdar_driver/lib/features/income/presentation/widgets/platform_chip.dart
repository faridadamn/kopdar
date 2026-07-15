import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Data for a platform chip option.
class PlatformOption {
  final String name;
  final String emoji;

  const PlatformOption({required this.name, required this.emoji});
}

/// Available platforms for income tracking.
const List<PlatformOption> platformOptions = [
  PlatformOption(name: 'Gojek', emoji: '🛵'),
  PlatformOption(name: 'Grab', emoji: '🚗'),
  PlatformOption(name: 'ShopeeFood', emoji: '🍔'),
  PlatformOption(name: 'Maxim', emoji: '🚕'),
  PlatformOption(name: 'InDrive', emoji: '🚙'),
  PlatformOption(name: 'Cash', emoji: '💵'),
  PlatformOption(name: 'Lainnya', emoji: '📋'),
];

/// Horizontally scrollable platform selector chips.
class PlatformChipList extends StatelessWidget {
  final String? selected;
  final ValueChanged<String>? onSelected;
  final bool showAll;

  const PlatformChipList({
    super.key,
    this.selected,
    this.onSelected,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: platformOptions.length + (showAll ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (showAll && index == 0) {
            return _PlatformChip(
              name: 'Semua',
              emoji: '📋',
              isSelected: selected == null || selected == 'Semua',
              onTap: () => onSelected?.call('Semua'),
            );
          }
          final opt = platformOptions[showAll ? index - 1 : index];
          return _PlatformChip(
            name: opt.name,
            emoji: opt.emoji,
            isSelected: selected == opt.name,
            onTap: () => onSelected?.call(opt.name),
          );
        },
      ),
    );
  }
}

/// A single platform selector chip.
class PlatformChip extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlatformChip({
    super.key,
    required this.name,
    required this.emoji,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PlatformChip(
      name: name,
      emoji: emoji,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}

class _PlatformChip extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PlatformChip({
    required this.name,
    required this.emoji,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
