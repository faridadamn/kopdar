import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/profile_provider.dart';
import '../widgets/referral_card.dart';

/// Referral page with code display, share buttons, stats, list.
class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchReferral();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🤝 Referral'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isReferralLoading && provider.referralInfo == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.referralStatus == ReferralStatus.error &&
              provider.referralInfo == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😵', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(provider.referralError ?? 'Terjadi kesalahan'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.fetchReferral,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final info = provider.referralInfo;

          return RefreshIndicator(
            onRefresh: provider.fetchReferral,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Apply referral code (if no code yet) ──
                if (info == null || info.code.isEmpty) ...[
                  _ApplyCodeSection(
                    controller: _codeCtrl,
                    isLoading: provider.referralStatus == ReferralStatus.applying,
                    errorText: provider.referralError,
                    onApply: () async {
                      if (_codeCtrl.text.trim().isEmpty) return;
                      final success = await provider
                          .applyReferralCode(_codeCtrl.text.trim());
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kode referral berhasil digunakan!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                if (info != null) ...[
                  // ── Referral code display ──
                  _CodeDisplay(code: info.code),
                  const SizedBox(height: 16),

                  // ── Share buttons ──
                  _ShareButtons(code: info.code),
                  const SizedBox(height: 20),

                  // ── Stats ──
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Total Referral',
                          value: '${info.totalReferrals}',
                          icon: Icons.people_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          label: 'Total Bonus',
                          value: Formatters.number(info.totalBonus),
                          icon: Icons.card_giftcard_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Referral list ──
                  Text(
                    'Daftar Referral',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (info.referrals.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('🔗', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada referral',
                            style: TextStyle(color: AppColors.gray500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bagikan kode Anda untuk mendapat bonus!',
                            style: TextStyle(
                              color: AppColors.gray400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...info.referrals.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ReferralCard(entry: entry),
                      ),
                    ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Section for applying a referral code.
class _ApplyCodeSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onApply;

  const _ApplyCodeSection({
    required this.controller,
    required this.isLoading,
    this.errorText,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan Kode Referral',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Dapatkan bonus poin dari teman yang mengundang Anda.',
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Contoh: KOPDAR123',
                    errorText: errorText,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isLoading ? null : onApply,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Gunakan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Referral code display with copy button.
class _CodeDisplay extends StatelessWidget {
  final String code;

  const _CodeDisplay({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Kode Referral Anda',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kode disalin!'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Salin Kode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Share buttons: WhatsApp, SMS, Copy.
class _ShareButtons extends StatelessWidget {
  final String code;

  const _ShareButtons({required this.code});

  @override
  Widget build(BuildContext context) {
    final message =
        'Gabung KopDar pakai kode referral saya: $code — Koperasi Digital untuk gig worker! 🚗💨';

    return Row(
      children: [
        Expanded(
          child: _ShareButton(
            icon: '💬',
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () {
              // Share via WhatsApp (would use url_launcher in production)
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesan disalin! Tempel di WhatsApp.'),
                  backgroundColor: Color(0xFF25D366),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShareButton(
            icon: '💬',
            label: 'SMS',
            color: AppColors.blue,
            onTap: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesan disalin! Tempel di SMS.'),
                  backgroundColor: AppColors.blue,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShareButton(
            icon: '📋',
            label: 'Salin',
            color: AppColors.gray600,
            onTap: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Teks referral disalin!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat box widget.
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
