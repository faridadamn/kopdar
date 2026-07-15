import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Redirect page — the real profile page is at
/// features/profile/presentation/pages/profil_page.dart
///
/// This placeholder simply redirects to /profile so the router
/// handles the correct page.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger redirect on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/profile');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
