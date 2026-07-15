import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/ride_model.dart';
import '../providers/ride_provider.dart';

/// Ride detail page showing full trip info.
class RideDetailPage extends StatefulWidget {
  final String rideId;

  const RideDetailPage({super.key, required this.rideId});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  RideModel? _ride;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRide();
  }

  Future<void> _loadRide() async {
    final provider = context.read<RideProvider>();
    // Try from cache first
    final cached = provider.rides.where((r) => r.id == widget.rideId).firstOrNull;
    if (cached != null) {
      setState(() {
        _ride = cached;
        _isLoading = false;
      });
      return;
    }
    // Fetch from API
    final ride = await provider.getRideDetail(widget.rideId);
    setState(() {
      _ride = ride;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Order')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final ride = _ride;
    if (ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Order')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📭', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Order tidak ditemukan.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text('${ride.platformName} — Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Earnings card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  ride.platformEmoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 10),
                Text(
                  Formatters.currency(ride.earnings),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ride.statusLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Route ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rute',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _RouteRow(
                  icon: Icons.circle,
                  iconColor: AppColors.primary,
                  label: 'Jemput',
                  address: ride.pickupAddress ?? '-',
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Container(
                    width: 2,
                    height: 20,
                    color: AppColors.gray300,
                  ),
                ),
                _RouteRow(
                  icon: Icons.location_on,
                  iconColor: AppColors.danger,
                  label: 'Tujuan',
                  address: ride.dropoffAddress ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Trip stats ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail Perjalanan',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: '🛣️',
                    label: 'Jarak',
                    value: ride.distanceFormatted),
                _DetailRow(
                    icon: '⏱️',
                    label: 'Durasi',
                    value: ride.durationFormatted),
                _DetailRow(
                    icon: '📅',
                    label: 'Tanggal',
                    value: Formatters.dateTime(ride.createdAt)),
                _DetailRow(
                    icon: '🚗',
                    label: 'Platform',
                    value: ride.platformName),
                if (ride.rating != null)
                  _DetailRow(
                    icon: '⭐',
                    label: 'Rating',
                    value: '${ride.rating!.toStringAsFixed(1)} / 5.0',
                  ),
                if (ride.note != null && ride.note!.isNotEmpty)
                  _DetailRow(
                    icon: '📝',
                    label: 'Catatan',
                    value: ride.note!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.gray500)),
              Text(address,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
