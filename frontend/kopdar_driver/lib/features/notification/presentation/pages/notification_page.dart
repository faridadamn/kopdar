import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

/// Notification inbox page with grouped list, read/dismiss all.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });

    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🔔 Notifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'read_all':
                      provider.markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua notifikasi ditandai sudah dibaca.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    case 'delete_all':
                      _confirmDeleteAll(context, provider);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Tandai Semua Dibaca'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined,
                            size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Hapus Semua',
                            style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.status == NotificationStatus.error &&
              provider.notifications.isEmpty) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: provider.fetchNotifications,
            );
          }

          if (provider.notifications.isEmpty) {
            return _EmptyState();
          }

          final grouped = provider.groupedByDate;

          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            color: AppColors.primary,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _itemCount(grouped, provider),
              itemBuilder: (context, index) {
                // Calculate which group and item
                int running = 0;
                for (final entry in grouped.entries) {
                  final sectionHeader = running;
                  final sectionItems = running + 1 + entry.value.length;

                  if (index == sectionHeader) {
                    // Section header
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: 10, top: 4, left: 4),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray500,
                        ),
                      ),
                    );
                  }

                  if (index < sectionItems) {
                    final itemIndex = index - running - 1;
                    final notification = entry.value[itemIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NotificationTile(
                        notification: notification,
                        onTap: () {
                          provider.markAsRead(notification.id);
                          final route = notification.route;
                          if (route != null) {
                            context.push(route);
                          } else {
                            context.push(
                                '/notification/detail/${notification.id}');
                          }
                        },
                        onDelete: () =>
                            provider.deleteNotification(notification.id),
                      ),
                    );
                  }

                  running = sectionItems;
                }

                // Loading more indicator
                if (provider.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  int _itemCount(
      Map<String, List<dynamic>> grouped, NotificationProvider provider) {
    int count = 0;
    for (final entry in grouped.entries) {
      count += 1 + entry.value.length; // header + items
    }
    if (provider.isLoadingMore) count += 1;
    return count;
  }

  void _confirmDeleteAll(
      BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi?'),
        content: const Text(
            'Semua notifikasi akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi dihapus.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Belum ada notifikasi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Notifikasi order, promo, dan info penting lainnya akan muncul di sini.',
              style: TextStyle(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
