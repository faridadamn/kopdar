import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/emergency_provider.dart';
import '../widgets/sos_button.dart';
import '../widgets/medical_info_card.dart';
import '../widgets/emergency_contact_card.dart';
import '../widgets/nearby_driver_tile.dart';

/// Full-screen SOS page with big red pulsing button, medical card,
/// contacts, nearby responders, and resolve button.
class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  String _selectedType = 'accident';
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmergencyProvider>();
      provider.checkActiveSOS();
      provider.fetchContacts();
      provider.fetchMedicalInfo();
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🚨 SOS Darurat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, _) {
          if (provider.hasActiveSOS) {
            return _ActiveSOSView(provider: provider);
          }
          return _TriggerSOSView(
            selectedType: _selectedType,
            descCtrl: _descCtrl,
            onTypeChanged: (v) => setState(() => _selectedType = v),
            onTrigger: () => _triggerSOS(provider),
            isLoading: provider.isLoading,
          );
        },
      ),
    );
  }

  Future<void> _triggerSOS(EmergencyProvider provider) async {
    final success = await provider.triggerSOS(
      type: _selectedType,
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : null,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinyal darurat berhasil dikirim!'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

/// View when no active SOS — user can trigger one.
class _TriggerSOSView extends StatelessWidget {
  final String selectedType;
  final TextEditingController descCtrl;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onTrigger;
  final bool isLoading;

  const _TriggerSOSView({
    required this.selectedType,
    required this.descCtrl,
    required this.onTypeChanged,
    required this.onTrigger,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // SOS Button
          SOSButton(
            onPressed: onTrigger,
            size: 120,
          ),
          const SizedBox(height: 16),
          Text(
            'Tekan tombol SOS untuk mengirim sinyal darurat',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Type selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jenis Darurat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TypeChip(
                      label: 'Kecelakaan',
                      icon: Icons.car_crash_rounded,
                      value: 'accident',
                      selected: selectedType == 'accident',
                      onTap: () => onTypeChanged('accident'),
                    ),
                    _TypeChip(
                      label: 'Mogok',
                      icon: Icons.build_rounded,
                      value: 'breakdown',
                      selected: selectedType == 'breakdown',
                      onTap: () => onTypeChanged('breakdown'),
                    ),
                    _TypeChip(
                      label: 'Medis',
                      icon: Icons.medical_services_rounded,
                      value: 'medical',
                      selected: selectedType == 'medical',
                      onTap: () => onTypeChanged('medical'),
                    ),
                    _TypeChip(
                      label: 'Kriminal',
                      icon: Icons.shield_rounded,
                      value: 'crime',
                      selected: selectedType == 'crime',
                      onTap: () => onTypeChanged('crime'),
                    ),
                    _TypeChip(
                      label: 'Lainnya',
                      icon: Icons.more_horiz_rounded,
                      value: 'other',
                      selected: selectedType == 'other',
                      onTap: () => onTypeChanged('other'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deskripsi (opsional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Jelaskan situasi darurat Anda...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (isLoading)
            const CircularProgressIndicator(color: AppColors.danger),
        ],
      ),
    );
  }
}

/// View when there is an active SOS.
class _ActiveSOSView extends StatefulWidget {
  final EmergencyProvider provider;

  const _ActiveSOSView({required this.provider});

  @override
  State<_ActiveSOSView> createState() => _ActiveSOSViewState();
}

class _ActiveSOSViewState extends State<_ActiveSOSView> {
  @override
  void initState() {
    super.initState();
    // Fetch nearby drivers if we have coordinates
    final sos = widget.provider.activeSOS;
    if (sos?.latitude != null && sos?.longitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.provider.fetchNearbyDrivers(
          latitude: sos!.latitude!,
          longitude: sos.longitude!,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final sos = provider.activeSOS!;

    return Column(
      children: [
        // Pulsing status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: sos.isActive
                  ? [AppColors.danger, const Color(0xFFB71C1C)]
                  : [AppColors.warning, const Color(0xFFE65100)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Text(
                  sos.isActive ? '🚨 DARURAT AKTIF' : '🚑 DALAM PENANGANAN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sos.typeLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Description if any
              if (sos.description != null && sos.description!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sos.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

              // Medical card
              if (provider.medicalInfo != null &&
                  provider.medicalInfo!.hasData) ...[
                MedicalInfoCard(medical: provider.medicalInfo!),
                const SizedBox(height: 16),
              ],

              // Emergency contacts
              if (provider.contacts.isNotEmpty) ...[
                Text(
                  'Kontak Darurat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...provider.contacts.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EmergencyContactCard(contact: c),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Nearby drivers
              if (provider.nearbyDrivers.isNotEmpty) ...[
                Text(
                  'Driver Terdekat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...provider.nearbyDrivers.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NearbyDriverTile(driver: d),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (provider.nearbyStatus == EmergencyStatus.loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Resolve button
              ElevatedButton.icon(
                onPressed: () => _confirmResolve(context, provider),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Selesaikan Darurat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmResolve(BuildContext context, EmergencyProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Darurat?'),
        content: const Text(
          'Pastikan situasi sudah aman. Kontak darurat akan diberitahu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.resolveSOS();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Darurat telah diselesaikan.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              'Ya, Selesaikan',
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip for selecting emergency type.
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.dangerLight : AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.danger : AppColors.gray300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.danger : AppColors.gray600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.danger : AppColors.gray700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
