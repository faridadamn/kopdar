import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/profile_provider.dart';
import '../widgets/membership_card.dart';
import '../widgets/stat_item.dart';

/// Main profile page with header, membership card, stats, and menu.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isProfileLoading && provider.profile == null) {
            return const _LoadingState();
          }

          if (provider.profileStatus == ProfileStatus.error &&
              provider.profile == null) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Terjadi kesalahan',
              onRetry: provider.fetchProfile,
            );
          }

          final profile = provider.profile;
          if (profile == null) {
            return const _LoadingState();
          }

          return RefreshIndicator(
            onRefresh: provider.fetchProfile,
            color: AppColors.primary,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Green gradient header ──
                _buildHeader(context, profile),
                const SizedBox(height: 16),

                // ── Membership card ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MembershipCard(profile: profile),
                ),
                const SizedBox(height: 20),

                // ── Stats row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StatItem(
                          emoji: '⭐',
                          value: profile.rating > 0
                              ? profile.rating.toStringAsFixed(1)
                              : '-',
                          label: 'Rating',
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: AppColors.gray200),
                        StatItem(
                          emoji: '📦',
                          value: Formatters.number(profile.totalOrders),
                          label: 'Order',
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: AppColors.gray200),
                        StatItem(
                          emoji: '📅',
                          value: Formatters.number(profile.activeDays),
                          label: 'Hari Aktif',
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: AppColors.gray200),
                        StatItem(
                          emoji: profile.levelEmoji,
                          value: profile.levelLabel,
                          label: 'Level',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Level progress bar ──
                if (profile.levelInfo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _LevelProgress(levelInfo: profile.levelInfo!),
                  ),
                const SizedBox(height: 20),

                // ── Menu items ──
                _MenuSection(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D3B1E), AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(profile.levelEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  profile.levelLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Level progress bar widget.
class _LevelProgress extends StatelessWidget {
  final dynamic levelInfo;

  const _LevelProgress({required this.levelInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Level',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${levelInfo.currentPoints} / ${levelInfo.nextLevelPoints} poin',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: levelInfo.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.gray200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(levelInfo.progress * 100).round()}% menuju ${_nextLevelName(levelInfo.nextLevel)}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  String _nextLevelName(String level) {
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

/// Menu section with navigation items.
class _MenuSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _MenuItem(
              icon: Icons.edit_rounded,
              label: 'Edit Profil',
              onTap: () => context.push('/profile/edit'),
            ),
            const _MenuDivider(),
            _MenuItem(
              icon: Icons.directions_car_rounded,
              label: 'Kendaraan Saya',
              onTap: () => context.push('/profile/vehicle'),
            ),
            const _MenuDivider(),
            _MenuItem(
              icon: Icons.description_outlined,
              label: 'Dokumen',
              onTap: () => context.push('/profile/documents'),
            ),
            const _MenuDivider(),
            _MenuItem(
              icon: Icons.military_tech_rounded,
              label: 'Level & Poin',

              onTap: () => context.push('/profile/level'),
            ),
            const _MenuDivider(),
            _MenuItem(
              icon: Icons.share_rounded,
              label: 'Referral',
              onTap: () => context.push('/profile/referral'),
            ),
            const _MenuDivider(),
            _MenuItem(
              icon: Icons.settings_rounded,
              label: 'Pengaturan',
              onTap: () => context.push('/profile/settings'),
            ),
            const _MenuDivider(),
            _MenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Bantuan',
              onTap: () => context.push('/help'),
            ),
            const _MenuDivider(),
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              color: AppColors.danger,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text(
            'Anda akan keluar dari akun KopDar. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileProvider>().logout();
              context.go('/login');
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? AppColors.gray600),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color ?? AppColors.gray800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: AppColors.gray200,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Memuat profil...', style: TextStyle(color: AppColors.gray500)),
        ],
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
