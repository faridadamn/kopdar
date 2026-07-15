import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../notification/presentation/widgets/notification_badge.dart';
import '../../notification/presentation/providers/notification_provider.dart';

/// Bottom navigation bar with 4 tabs + notification badge.
class KopDarBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KopDarBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: '🏠', label: 'Beranda'),
    _NavItem(icon: '📊', label: 'Keuangan'),
    _NavItem(icon: '👥', label: 'Komunitas'),
    _NavItem(icon: '👤', label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index == 0)
                        // Home tab with notification badge
                        _HomeTabWithBadge(isActive: isActive)
                      else
                        Text(
                          item.icon,
                          style: TextStyle(
                            fontSize: 22,
                            color: isActive ? null : AppColors.gray400,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.gray400,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Home tab with notification badge overlay.
class _HomeTabWithBadge extends StatelessWidget {
  final bool isActive;

  const _HomeTabWithBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return NotificationBadge(
      count: unreadCount,
      size: 22,
      iconColor: isActive ? null : AppColors.gray400,
    );
  }
}

class _NavItem {
  final String icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
