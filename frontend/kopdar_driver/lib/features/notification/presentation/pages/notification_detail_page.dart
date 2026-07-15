import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/core/utils/formatters.dart';
import 'package:kopdar_driver/features/notification/data/models/notification_model.dart';
import 'package:kopdar_driver/features/notification/presentation/providers/notification_provider.dart';

/// Notification detail page showing full content.
class NotificationDetailPage extends StatelessWidget {
  final String notificationId;

  const NotificationDetailPage({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        NotificationModel? notification;
        for (final item in provider.notifications) {
          if (item.id == notificationId) {
            notification = item;
            break;
          }
        }

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

        final item = notification;
        if (!item.isRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.markAsRead(item.id);
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
                onPressed: () async {
                  await provider.deleteNotification(item.id);
                  if (context.mounted) context.pop();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor(item.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.typeEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.typeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _typeColor(item.type),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      Formatters.relativeTime(item.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 16),
              if (item.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    item.imageUrl!,
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
                      alignment: Alignment.center,
                      child: Text(
                        item.typeEmoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.gray800,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (item.route != null)
                ElevatedButton.icon(
                  onPressed: () => context.push(item.route!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(_actionLabel(item.type)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor(item.type),
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
      case 'savings':
        return AppColors.primary;
      case 'sos':
        return AppColors.danger;
      case 'referral':
      case 'payment':
        return AppColors.success;
      case 'insurance':
        return AppColors.blue;
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
