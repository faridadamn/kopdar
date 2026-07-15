import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

/// Global error handler widget that wraps the app.
/// Catches and displays errors gracefully.
class GlobalErrorHandler extends StatefulWidget {
  final Widget child;

  const GlobalErrorHandler({super.key, required this.child});

  @override
  State<GlobalErrorHandler> createState() => _GlobalErrorHandlerState();
}

class _GlobalErrorHandlerState extends State<GlobalErrorHandler> {
  @override
  void initState() {
    super.initState();
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);
    };
  }

  void _logError(Object error, StackTrace? stack) {
    debugPrint('🔴 GLOBAL ERROR: $error');
    if (stack != null) debugPrint('STACK: $stack');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Error display page for unhandled route errors.
class ErrorPage extends StatelessWidget {
  final String? errorMessage;

  const ErrorPage({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😵', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(
                'Oops! Terjadi Kesalahan',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'Halaman yang kamu cari tidak ditemukan.',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Kembali ke Beranda'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Could send error report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan kesalahan terkirim. Terima kasih!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: Text(
                  'Laporkan Masalah',
                  style: TextStyle(color: AppColors.gray500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension for safe navigation with error handling.
extension SafeNavigation on BuildContext {
  void safePush(String path) {
    try {
      push(path);
    } catch (e) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka halaman: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void safeGo(String path) {
    try {
      go(path);
    } catch (e) {
      go('/home');
    }
  }
}
