import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

/// Notification detail page showing full content.
class NotificationDetailPage extends StatelessWidget {
  final String notificationId;

  const NotificationDetailPage({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final notification = provider.notifications
            .where((n) => n.id == notificationId)
            .firstOrNull;

        if (notification == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detail Notifikasi'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📭', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text('Notifikasi tidak ditemukan.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          );
        }

        // Mark as read when viewing
        if (!notification.isRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.markAsRead(notification.id);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.gray50,
          appBar: AppBar(
            title: const Text('Detail Notifikasi'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () {
                  provider.deleteNotification(notification.id);
                  context.pop();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Type badge ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _typeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(notification.typeEmoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          notification.typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _typeColor(notification.type),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Formatters.relativeTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Title ──
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 16),

              // ── Image if any ──
              if (notification.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    notification.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          notification.typeEmoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Body ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.gray800,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Deep link button ──
              if (notification.route != null)
                ElevatedButton.icon(
                  onPressed: () => context.push(notification.route!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(_actionLabel(notification.type)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor(notification.type),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.info;
      case 'promo':
        return AppColors.accent;
      case 'community':
        return AppColors.primary;
      case 'sos':
        return AppColors.danger;
      case 'referral':
        return AppColors.success;
      case 'savings':
        return AppColors.primary;
      case 'insurance':
        return AppColors.blue;
      case 'payment':
        return AppColors.success;
      case 'level':
        return AppColors.warning;
      default:
        return AppColors.gray500;
    }
  }

  String _actionLabel(String type) {
    switch (type) {
      case 'order':
        return 'Lihat Detail Order';
      case 'promo':
        return 'Lihat Promo';
      case 'community':
        return 'Lihat Postingan';
      case 'sos':
        return 'Buka Halaman Darurat';
      case 'referral':
        return 'Lihat Referral';
      case 'savings':
        return 'Lihat Tabungan';
      case 'insurance':
        return 'Lihat Asuransi';
      default:
        return 'Lihat Detail';
    }
  }
}
