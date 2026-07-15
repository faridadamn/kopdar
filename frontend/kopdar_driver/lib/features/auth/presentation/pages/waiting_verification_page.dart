import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:kopdar_driver/config/theme.dart';
import 'package:kopdar_driver/features/auth/presentation/providers/auth_provider.dart';

class WaitingVerificationPage extends StatefulWidget {
  const WaitingVerificationPage({super.key});

  @override
  State<WaitingVerificationPage> createState() =>
      _WaitingVerificationPageState();
}

class _WaitingVerificationPageState extends State<WaitingVerificationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final auth = context.read<AuthProvider>();
    await auth.checkVerificationStatus();

    if (!mounted) return;
    setState(() => _isChecking = false);

    switch (auth.status) {
      case AuthStatus.authenticated:
        context.go('/home');
        return;
      case AuthStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Verifikasi belum berhasil.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun masih dalam proses verifikasi.'),
            backgroundColor: AppColors.primary,
          ),
        );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text(
          'Pendaftaran tetap tersimpan. Kamu dapat masuk kembali untuk mengecek statusnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (_pulseController.value * 10),
                    height: 120 + (_pulseController.value * 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg.withValues(
                        alpha: 1 - (_pulseController.value * 0.3),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: child,
                  );
                },
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 600.ms),
              const SizedBox(height: 32),
              Text(
                'Menunggu Verifikasi',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Akun sedang diverifikasi admin.\nProses biasanya selesai kurang dari 24 jam.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray600,
                      height: 1.6,
                    ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sedang diproses',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_isChecking ? 'Mengecek...' : 'Cek Status'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
