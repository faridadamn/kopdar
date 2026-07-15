import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Rewards & Loyalty page: tukar poin, leaderboard, achievements.
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _rewards = [
    _RewardItem(
        icon: '💰', title: 'Saldo Rp 25.000', points: 500, category: 'Saldo'),
    _RewardItem(
        icon: '💰', title: 'Saldo Rp 50.000', points: 1000, category: 'Saldo'),
    _RewardItem(
        icon: '🎟️', title: 'Voucher Grab 20%', points: 200, category: 'Voucher'),
    _RewardItem(
        icon: '🎟️', title: 'Voucher GoFood Rp 15rb', points: 300, category: 'Voucher'),
    _RewardItem(
        icon: '👕', title: 'Kaos KopDar', points: 2000, category: 'Merchandise'),
    _RewardItem(
        icon: '🧢', title: 'Topi KopDar', points: 800, category: 'Merchandise'),
    _RewardItem(
        icon: '🪖', title: 'Helm Gratis', points: 5000, category: 'Merchandise'),
    _RewardItem(
        icon: '⛽', title: 'Voucher BBM Rp 50rb', points: 1200, category: 'Voucher'),
  ];

  static const _leaderboard = [
    _LeaderItem(rank: 1, name: 'Budi Santoso', points: 15200, level: '💎'),
    _LeaderItem(rank: 2, name: 'Andi Wijaya', points: 12800, level: '🥇'),
    _LeaderItem(rank: 3, name: 'Dewi Lestari', points: 11500, level: '🥇'),
    _LeaderItem(rank: 4, name: 'Rizky Pratama', points: 9800, level: '🥈'),
    _LeaderItem(rank: 5, name: 'Siti Nurhaliza', points: 8200, level: '🥈'),
    _LeaderItem(rank: 6, name: 'Ahmad Fauzi', points: 7100, level: '🥈'),
    _LeaderItem(rank: 7, name: 'Maya Angelina', points: 6500, level: '🥉'),
    _LeaderItem(rank: 8, name: 'Kamu', points: 5800, level: '🥉', isMe: true),
  ];

  static const _achievements = [
    _AchievementItem(
        icon: '🎯', title: 'Order Pertama', desc: 'Selesaikan order pertamamu', done: true),
    _AchievementItem(
        icon: '📦', title: '100 Order', desc: 'Selesaikan 100 order', done: true),
    _AchievementItem(
        icon: '💰', title: 'Jutawan', desc: 'Total pendapatan Rp 1.000.000', done: true),
    _AchievementItem(
        icon: '📅', title: '30 Hari Berturut', desc: 'Login 30 hari tanpa putus', done: false, progress: 0.7),
    _AchievementItem(
        icon: '🤝', title: 'Referral Master', desc: 'Undang 10 teman', done: false, progress: 0.3),
    _AchievementItem(
        icon: '⭐', title: 'Rating Sempurna', desc: 'Dapat rating 5.0 selama 50 order', done: false, progress: 0.6),
    _AchievementItem(
        icon: '🐷', title: 'Penabung Hebat', desc: 'Tabung selama 30 hari berturut', done: false, progress: 0.4),
    _AchievementItem(
        icon: '🦸', title: 'Pahlawan Darurat', desc: 'Bantu 5 driver dalam situasi SOS', done: false, progress: 0.0),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🏆 Rewards & Loyalty'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Tukar Poin'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Pencapaian'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RewardsTab(rewards: _rewards),
          _LeaderboardTab(entries: _leaderboard),
          _AchievementsTab(achievements: _achievements),
        ],
      ),
    );
  }
}

/// ── Rewards Tab ──
class _RewardsTab extends StatelessWidget {
  final List<_RewardItem> rewards;

  const _RewardsTab({required this.rewards});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final userPoints = profile?.points ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Points balance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text('Poin Kamu',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                Formatters.number(userPoints),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tukarkan dengan reward menarik!',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Rewards grid
        Text('Tersedia',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: rewards.length,
          itemBuilder: (_, i) {
            final r = rewards[i];
            final canRedeem = userPoints >= r.pointsCost;
            return _RewardGridCard(
              reward: r,
              canRedeem: canRedeem,
              onTap: canRedeem
                  ? () => _confirmRedeem(context, r)
                  : null,
            );
          },
        ),
      ],
    );
  }

  void _confirmRedeem(BuildContext context, _RewardItem reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tukar ${reward.title}?'),
        content: Text(
            'Poin kamu akan dikurangi ${Formatters.number(reward.pointsCost)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${reward.title} berhasil ditukar! 🎉'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
  }
}

class _RewardGridCard extends StatelessWidget {
  final _RewardItem reward;
  final bool canRedeem;
  final VoidCallback? onTap;

  const _RewardGridCard({
    required this.reward,
    required this.canRedeem,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canRedeem
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.gray200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(reward.icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              reward.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: canRedeem
                    ? AppColors.primaryBg
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${Formatters.number(reward.pointsCost)} poin',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color:
                      canRedeem ? AppColors.primary : AppColors.gray400,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reward.category,
              style: TextStyle(fontSize: 10, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Leaderboard Tab ──
class _LeaderboardTab extends StatelessWidget {
  final List<_LeaderItem> entries;

  const _LeaderboardTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: e.isMe ? AppColors.primaryBg : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: e.isMe
                ? Border.all(color: AppColors.primary.withOpacity(0.4))
                : null,
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: Text(
                  '#${e.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: e.rank <= 3
                        ? AppColors.warning
                        : AppColors.gray600,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.gray100,
                child: Text(
                  e.name[0],
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),

              // Name + level
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: TextStyle(
                        fontWeight:
                            e.isMe ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      e.level,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Points
              Text(
                Formatters.number(e.points),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color:
                      e.isMe ? AppColors.primary : AppColors.gray800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ── Achievements Tab ──
class _AchievementsTab extends StatelessWidget {
  final List<_AchievementItem> achievements;

  const _AchievementsTab({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final done = achievements.where((a) => a.done).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$done dari ${achievements.length} terbuka',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: done / achievements.length,
                        minHeight: 8,
                        backgroundColor: AppColors.gray200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List
        ...achievements.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AchievementTile(achievement: a),
            )),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final _AchievementItem achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: achievement.done ? AppColors.white : AppColors.gray100,
        borderRadius: BorderRadius.circular(14),
        border: achievement.done
            ? Border.all(color: AppColors.success.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: achievement.done
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(achievement.icon,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: achievement.done
                        ? AppColors.gray900
                        : AppColors.gray600,
                  ),
                ),
                Text(
                  achievement.desc,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.gray500),
                ),
                if (!achievement.done && achievement.progress > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 5,
                      backgroundColor: AppColors.gray300,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (achievement.done)
            const Icon(Icons.check_circle,
                color: AppColors.success, size: 22),
        ],
      ),
    );
  }
}

// ── Data classes ──

class _RewardItem {
  final String icon;
  final String title;
  final int points;
  final String category;

  const _RewardItem({
    required this.icon,
    required this.title,
    required this.points,
    required this.category,
  });
}

class _LeaderItem {
  final int rank;
  final String name;
  final int points;
  final String level;
  final bool isMe;

  const _LeaderItem({
    required this.rank,
    required this.name,
    required this.points,
    required this.level,
    this.isMe = false,
  });
}

class _AchievementItem {
  final String icon;
  final String title;
  final String desc;
  final bool done;
  final double progress;

  const _AchievementItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.done,
    this.progress = 0.0,
  });
}
