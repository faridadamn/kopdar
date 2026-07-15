import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Notification badge widget — shows count on bell icon.
class NotificationBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color? iconColor;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size = 24,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.notifications_rounded,
          size: size,
          color: iconColor ?? AppColors.gray700,
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
