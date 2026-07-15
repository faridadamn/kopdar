import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/profile_provider.dart';
import '../widgets/level_badge.dart';
import '../widgets/points_history_tile.dart';

/// Level & Points page showing current level, progress, benefits, history.
class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchLevel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🏆 Level & Poin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLevelLoading && provider.levelInfo == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.levelStatus == LevelStatus.error &&
              provider.levelInfo == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😵', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text('Gagal memuat data level.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.fetchLevel,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final info = provider.levelInfo;
          if (info == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: provider.fetchLevel,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Big level badge ──
                Center(
                  child: LevelBadgeWithLabel(
                    level: info.currentLevel,
                    badgeSize: 100,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Points display ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${Formatters.number(info.currentPoints)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Poin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: info.progress.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${Formatters.number(info.nextLevelPoints - info.currentPoints)} poin lagi untuk ${_levelName(info.nextLevel)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Level comparison ──
                Text(
                  'Level & Keuntungan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _LevelComparison(
                  currentLevel: info.currentLevel,
                  benefits: info.benefits,
                ),
                const SizedBox(height: 24),

                // ── Points history ──
                Text(
                  'Riwayat Poin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (info.pointsHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat poin',
                          style: TextStyle(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      itemCount: info.pointsHistory.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppColors.gray200,
                      ),
                      itemBuilder: (_, i) =>
                          PointsHistoryTile(entry: info.pointsHistory[i]),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _levelName(String level) {
    switch (level.toLowerCase()) {
      case 'platinum':
        return 'Platinum';
      case 'gold':
        return 'Emas';
      case 'silver':
        return 'Perak';
      default:
        return level;
    }
  }
}

/// Level comparison showing all tiers.
class _LevelComparison extends StatelessWidget {
  final String currentLevel;
  final List<dynamic> benefits;

  const _LevelComparison({
    required this.currentLevel,
    required this.benefits,
  });

  static const _levels = [
    {'key': 'bronze', 'emoji': '🥉', 'name': 'Perunggu', 'min': '0'},
    {'key': 'silver', 'emoji': '🥈', 'name': 'Perak', 'min': '500'},
    {'key': 'gold', 'emoji': '🥇', 'name': 'Emas', 'min': '2.000'},
    {'key': 'platinum', 'emoji': '💎', 'name': 'Platinum', 'min': '10.000'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _levels.map((lvl) {
          final isCurrent = lvl['key'] == currentLevel;
          final isUnlocked = _isUnlocked(lvl['key']!);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primaryBg : null,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gray200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(lvl['emoji']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lvl['name']!,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 15,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.gray800,
                        ),
                      ),
                      Text(
                        'Min. ${lvl['min']} poin',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Saat Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (isUnlocked)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20)
                else
                  Icon(Icons.lock_outline, color: AppColors.gray400, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isUnlocked(String level) {
    const order = ['bronze', 'silver', 'gold', 'platinum'];
    final currentIdx = order.indexOf(currentLevel);
    final checkIdx = order.indexOf(level);
    return checkIdx <= currentIdx;
  }
}
