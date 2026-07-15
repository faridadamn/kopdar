import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/profile_provider.dart';

/// Settings page: Bahasa, Zona, Auto-Tabung, Notifikasi, Keamanan, etc.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('⚙️ Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isSettingsLoading && provider.settings == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final settings = provider.settings;
          if (settings == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😵', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text('Gagal memuat pengaturan.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.fetchSettings,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Umum ──
              _SectionHeader(title: 'Umum'),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: 'Bahasa',
                    trailing: _languageName(settings.language),
                    onTap: () => _showLanguagePicker(context, provider),
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.access_time_rounded,
                    label: 'Zona Waktu',
                    trailing: settings.timezone,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Zona waktu otomatis dari perangkat.'),
                        ),
                      );
                    },
                  ),
                  const _TileDivider(),
                  _SwitchTile(
                    icon: Icons.savings_rounded,
                    label: 'Auto-Tabung',
                    subtitle: 'Potong otomatis dari penghasilan harian',
                    value: settings.autoSave,
                    onChanged: (v) =>
                        provider.updateSetting('auto_save', v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Notifikasi ──
              _SectionHeader(title: 'Notifikasi'),
              _SettingsCard(
                children: [
                  _SwitchTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Notifikasi Order',
                    value: settings.notifOrder,
                    onChanged: (v) =>
                        provider.updateSetting('notif_order', v),
                  ),
                  const _TileDivider(),
                  _SwitchTile(
                    icon: Icons.local_offer_rounded,
                    label: 'Notifikasi Promo',
                    value: settings.notifPromo,
                    onChanged: (v) =>
                        provider.updateSetting('notif_promo', v),
                  ),
                  const _TileDivider(),
                  _SwitchTile(
                    icon: Icons.group_rounded,
                    label: 'Notifikasi Komunitas',
                    value: settings.notifCommunity,
                    onChanged: (v) =>
                        provider.updateSetting('notif_community', v),
                  ),
                  const _TileDivider(),
                  _SwitchTile(
                    icon: Icons.emergency_rounded,
                    label: 'Notifikasi SOS',
                    value: settings.notifSOS,
                    onChanged: (v) =>
                        provider.updateSetting('notif_sos', v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Keamanan ──
              _SectionHeader(title: 'Keamanan'),
              _SettingsCard(
                children: [
                  _SwitchTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'Autentikasi Biometrik',
                    subtitle: 'Gunakan sidik jari atau Face ID',
                    value: settings.biometricEnabled,
                    onChanged: (v) =>
                        provider.updateSetting('biometric_enabled', v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Tentang ──
              _SectionHeader(title: 'Tentang'),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Versi Aplikasi',
                    trailing: settings.appVersion,
                    onTap: () {},
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    label: 'Syarat & Ketentuan',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Syarat & Ketentuan — Segera hadir!'),
                        ),
                      );
                    },
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Kebijakan Privasi',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kebijakan Privasi — Segera hadir!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Bantuan ──
              _SectionHeader(title: 'Bantuan'),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Pusat Bantuan',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pusat Bantuan — Segera hadir!'),
                        ),
                      );
                    },
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Hubungi Kami',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hubungi Kami — Segera hadir!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Hapus Akun ──
              _DangerButton(
                label: 'Hapus Akun',
                subtitle: 'Tindakan ini tidak dapat dibatalkan',
                onTap: () => _confirmDeleteAccount(context, provider),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _languageName(String code) {
    switch (code) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  void _showLanguagePicker(BuildContext context, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Pilih Bahasa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _LanguageOption(
              label: 'Bahasa Indonesia',
              value: 'id',
              current: provider.settings?.language ?? 'id',
              onSelect: (v) {
                provider.updateSetting('language', v);
                Navigator.pop(ctx);
              },
            ),
            _LanguageOption(
              label: 'English',
              value: 'en',
              current: provider.settings?.language ?? 'id',
              onSelect: (v) {
                provider.updateSetting('language', v);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(
      BuildContext context, ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text(
          'Semua data Anda akan dihapus secara permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteAccount();
              if (success && context.mounted) {
                provider.logout();
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Akun berhasil dihapus.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text(
              'Hapus Permanen',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.gray500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Card container for settings group.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

/// Tappable settings tile.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
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
            Icon(icon, size: 22, color: AppColors.gray600),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray800,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.gray500,
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

/// Switch settings tile.
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.gray600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Divider between tiles.
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: AppColors.gray200,
    );
  }
}

/// Language option for bottom sheet.
class _LanguageOption extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onSelect;

  const _LanguageOption({
    required this.label,
    required this.value,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () => onSelect(value),
    );
  }
}

/// Danger button (e.g. delete account).
class _DangerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.delete_forever_rounded,
                color: AppColors.danger, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.danger.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
