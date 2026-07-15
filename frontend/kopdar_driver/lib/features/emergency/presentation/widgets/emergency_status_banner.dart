import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Pulsing red banner shown when an emergency is active.
class EmergencyStatusBanner extends StatefulWidget {
  final String status; // 'active' or 'responding'
  final String? typeLabel;
  final VoidCallback? onTap;

  const EmergencyStatusBanner({
    super.key,
    required this.status,
    this.typeLabel,
    this.onTap,
  });

  @override
  State<EmergencyStatusBanner> createState() => _EmergencyStatusBannerState();
}

class _EmergencyStatusBannerState extends State<EmergencyStatusBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor =>
      widget.status == 'active' ? AppColors.danger : AppColors.warning;

  String get _statusText {
    switch (widget.status) {
      case 'active':
        return '🚨 DARURAT AKTIF';
      case 'responding':
        return '🚑 DALAM PENANGANAN';
      default:
        return '⚠️ STATUS DARURAT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: _backgroundColor,
            boxShadow: [
              BoxShadow(
                color: _backgroundColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
                if (widget.typeLabel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.typeLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

