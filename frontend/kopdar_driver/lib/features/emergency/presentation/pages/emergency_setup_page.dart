import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/emergency_provider.dart';
import '../widgets/emergency_contact_card.dart';

/// Emergency setup page: medical info form + emergency contacts list.
class EmergencySetupPage extends StatefulWidget {
  const EmergencySetupPage({super.key});

  @override
  State<EmergencySetupPage> createState() => _EmergencySetupPageState();
}

class _EmergencySetupPageState extends State<EmergencySetupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmergencyProvider>();
      provider.fetchContacts();
      provider.fetchMedicalInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🚨 Pengaturan Darurat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Medical Info Section ──
              _SectionHeader(
                icon: Icons.medical_information_rounded,
                title: 'Info Medis',
                color: AppColors.blue,
                onAction: () => context.push('/emergency/medical'),
                actionLabel: provider.medicalInfo != null ? 'Edit' : 'Isi',
              ),
              const SizedBox(height: 12),
              if (provider.medicalStatus == EmergencyStatus.loading)
                const _MiniLoader()
              else if (provider.medicalInfo != null &&
                  provider.medicalInfo!.hasData)
                _MedicalSummary(medical: provider.medicalInfo!)
              else
                _EmptySection(
                  icon: Icons.medical_information_outlined,
                  message:
                      'Isi info medis untuk mempercepat penanganan darurat.',
                  buttonLabel: 'Isi Info Medis',
                  onPressed: () => context.push('/emergency/medical'),
                ),
              const SizedBox(height: 28),

              // ── Emergency Contacts Section ──
              _SectionHeader(
                icon: Icons.contacts_rounded,
                title: 'Kontak Darurat',
                color: AppColors.primary,
                onAction: () => _showAddContactSheet(context, provider),
                actionLabel: 'Tambah',
              ),
              const SizedBox(height: 12),
              if (provider.contactsStatus == EmergencyStatus.loading)
                const _MiniLoader()
              else if (provider.contacts.isEmpty)
                _EmptySection(
                  icon: Icons.contact_phone_outlined,
                  message:
                      'Tambahkan kontak yang akan dihubungi saat darurat.',
                  buttonLabel: 'Tambah Kontak',
                  onPressed: () => _showAddContactSheet(context, provider),
                )
              else
                ...provider.contacts.map(
                  (contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EmergencyContactCard(
                      contact: contact,
                      onDelete: () => _confirmDelete(context, provider, contact.id),
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // ── SOS Button ──
              Center(
                child: Column(
                  children: [
                    Text(
                      'Tombol SOS akan muncul di layar utama',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/emergency/sos'),
                      icon: const Icon(Icons.emergency_rounded),
                      label: const Text('Buka Halaman SOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _showAddContactSheet(
      BuildContext context, EmergencyProvider provider) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRelation = 'keluarga';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Kontak Darurat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRelation,
                    decoration: const InputDecoration(
                      labelText: 'Hubungan',
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'keluarga', child: Text('Keluarga')),
                      DropdownMenuItem(
                          value: 'pasangan', child: Text('Pasangan')),
                      DropdownMenuItem(
                          value: 'teman', child: Text('Teman')),
                      DropdownMenuItem(
                          value: 'lainnya', child: Text('Lainnya')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedRelation = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          phoneCtrl.text.trim().isEmpty) return;

                      final success = await provider.addContact(
                        name: nameCtrl.text.trim(),
                        phoneNumber: phoneCtrl.text.trim(),
                        relation: selectedRelation,
                      );
                      if (success && ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Simpan Kontak'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, EmergencyProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kontak?'),
        content: const Text('Kontak darurat ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteContact(id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onAction;
  final String actionLabel;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 17,
              ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(actionLabel),
          style: TextButton.styleFrom(foregroundColor: color),
        ),
      ],
    );
  }
}

class _MedicalSummary extends StatelessWidget {
  final dynamic medical; // DriverMedicalModel

  const _MedicalSummary({required this.medical});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          if (medical.bloodType != null)
            _SummaryRow(
                label: 'Golongan Darah', value: medical.bloodType!),
          if (medical.allergies.isNotEmpty)
            _SummaryRow(
                label: 'Alergi', value: medical.allergies.join(', ')),
          if (medical.conditions.isNotEmpty)
            _SummaryRow(
                label: 'Kondisi', value: medical.conditions.join(', ')),
          if (medical.medications.isNotEmpty)
            _SummaryRow(
                label: 'Obat', value: medical.medications.join(', ')),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.gray600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _EmptySection({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.gray400),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
