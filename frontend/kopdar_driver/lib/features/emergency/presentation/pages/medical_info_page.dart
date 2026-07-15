import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/emergency_provider.dart';

/// View/edit medical info page — blood type, allergies, conditions, meds.
class MedicalInfoPage extends StatefulWidget {
  const MedicalInfoPage({super.key});

  @override
  State<MedicalInfoPage> createState() => _MedicalInfoPageState();
}

class _MedicalInfoPageState extends State<MedicalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String? _bloodType;
  final _allergyCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _medicationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();

  List<String> _allergies = [];
  List<String> _conditions = [];
  List<String> _medications = [];

  bool _initialized = false;

  static const _bloodTypes = [
    'A', 'B', 'AB', 'O',
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyProvider>().fetchMedicalInfo();
    });
  }

  void _populateFields(dynamic medical) {
    if (_initialized || medical == null) return;
    _initialized = true;
    _bloodType = medical.bloodType;
    _allergies = List<String>.from(medical.allergies);
    _conditions = List<String>.from(medical.conditions);
    _medications = List<String>.from(medical.medications);
    _notesCtrl.text = medical.emergencyNotes ?? '';
    _hospitalCtrl.text = medical.hospitalPreference ?? '';
  }

  @override
  void dispose() {
    _allergyCtrl.dispose();
    _conditionCtrl.dispose();
    _medicationCtrl.dispose();
    _notesCtrl.dispose();
    _hospitalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('🏥 Info Medis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, _) {
          if (provider.medicalStatus == EmergencyStatus.loading &&
              !_initialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }

          _populateFields(provider.medicalInfo);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue, Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.medical_information_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Medis Darurat',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Data ini akan ditampilkan saat Anda mengirim sinyal SOS.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Blood Type
                Text('Golongan Darah',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bloodTypes.map((bt) {
                    final selected = _bloodType == bt;
                    return GestureDetector(
                      onTap: () => setState(() => _bloodType = bt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.blueLight : AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.blue
                                : AppColors.gray300,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          bt,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.blue
                                : AppColors.gray700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Allergies
                _TagInputField(
                  label: 'Alergi',
                  hint: 'Contoh: Kacang, Udang, Debu...',
                  controller: _allergyCtrl,
                  tags: _allergies,
                  color: AppColors.warning,
                  onAdd: (v) => setState(() => _allergies.add(v)),
                  onRemove: (i) => setState(() => _allergies.removeAt(i)),
                ),
                const SizedBox(height: 20),

                // Conditions
                _TagInputField(
                  label: 'Kondisi Kesehatan',
                  hint: 'Contoh: Diabetes, Asma, Darah Tinggi...',
                  controller: _conditionCtrl,
                  tags: _conditions,
                  color: AppColors.danger,
                  onAdd: (v) => setState(() => _conditions.add(v)),
                  onRemove: (i) => setState(() => _conditions.removeAt(i)),
                ),
                const SizedBox(height: 20),

                // Medications
                _TagInputField(
                  label: 'Obat Rutin',
                  hint: 'Contoh: Metformin, Ventolin...',
                  controller: _medicationCtrl,
                  tags: _medications,
                  color: AppColors.primary,
                  onAdd: (v) => setState(() => _medications.add(v)),
                  onRemove: (i) => setState(() => _medications.removeAt(i)),
                ),
                const SizedBox(height: 20),

                // Emergency Notes
                Text('Catatan Darurat',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Informasi penting untuk petugas medis...',
                  ),
                ),
                const SizedBox(height: 20),

                // Hospital Preference
                Text('Rumah Sakit Pilihan',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hospitalCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nama RS terdekat yang Anda inginkan...',
                    prefixIcon: Icon(Icons.local_hospital_rounded),
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                ElevatedButton.icon(
                  onPressed: () => _save(provider),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Simpan Info Medis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(EmergencyProvider provider) async {
    final success = await provider.saveMedicalInfo(
      bloodType: _bloodType,
      allergies: _allergies,
      conditions: _conditions,
      medications: _medications,
      emergencyNotes: _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : null,
      hospitalPreference: _hospitalCtrl.text.trim().isNotEmpty
          ? _hospitalCtrl.text.trim()
          : null,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Info medis berhasil disimpan!'),
          backgroundColor: AppColors.blue,
        ),
      );
      context.pop();
    }
  }
}

/// Reusable tag/chip input field.
class _TagInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final List<String> tags;
  final Color color;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _TagInputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.tags,
    required this.color,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    onAdd(v.trim());
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                  controller.clear();
                }
              },
              icon: const Icon(Icons.add_circle_rounded),
              color: color,
              iconSize: 32,
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(tags.length, (i) {
              return Chip(
                label: Text(
                  tags[i],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide.none,
                deleteIcon: Icon(Icons.close_rounded, size: 16, color: color),
                onDeleted: () => onRemove(i),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
          ),
        ],
      ],
    );
  }
}
