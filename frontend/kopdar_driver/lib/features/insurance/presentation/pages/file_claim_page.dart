import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../data/models/insurance_model.dart';
import '../providers/insurance_provider.dart';

/// File a claim form page.
class FileClaimPage extends StatefulWidget {
  const FileClaimPage({super.key});

  @override
  State<FileClaimPage> createState() => _FileClaimPageState();
}

class _FileClaimPageState extends State<FileClaimPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedPolicyId;
  String _claimType = 'accident';
  final List<String> _evidencePaths = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsuranceProvider>().fetchPolicies();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Ajukan Klaim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<InsuranceProvider>(
        builder: (context, provider, _) {
          final activePolicies = provider.activePolicies;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header info ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.blueLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text('ℹ️', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Isi form berikut untuk mengajukan klaim asuransi. Pastikan data yang dimasukkan benar.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Select policy ──
                        const Text(
                          'Pilih Polis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedPolicyId,
                          decoration: const InputDecoration(
                            hintText: 'Pilih polis aktif',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          items: activePolicies
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    '${p.productName} (${p.policyNumber})',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedPolicyId = v),
                          validator: (v) =>
                              v == null ? 'Pilih polis terlebih dahulu' : null,
                        ),
                        const SizedBox(height: 20),

                        // ── Claim type ──
                        const Text(
                          'Jenis Klaim',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _ClaimTypeChip(
                              emoji: '🚑',
                              label: 'Kecelakaan',
                              value: 'accident',
                              selected: _claimType == 'accident',
                              onTap: () =>
                                  setState(() => _claimType = 'accident'),
                            ),
                            const SizedBox(width: 8),
                            _ClaimTypeChip(
                              emoji: '🏥',
                              label: 'Rawat Inap',
                              value: 'inpatient',
                              selected: _claimType == 'inpatient',
                              onTap: () =>
                                  setState(() => _claimType = 'inpatient'),
                            ),
                            const SizedBox(width: 8),
                            _ClaimTypeChip(
                              emoji: '🛵',
                              label: 'Kendaraan',
                              value: 'vehicle',
                              selected: _claimType == 'vehicle',
                              onTap: () =>
                                  setState(() => _claimType = 'vehicle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Description ──
                        const Text(
                          'Deskripsi Kejadian',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText:
                                'Ceritakan kronologi kejadian secara detail (min. 50 karakter)',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Deskripsi wajib diisi';
                            }
                            if (v.length < 50) {
                              return 'Minimal 50 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _descriptionController,
                          builder: (context, value, _) {
                            final len = value.text.length;
                            return Text(
                              '$len karakter',
                              style: TextStyle(
                                fontSize: 11,
                                color: len >= 50
                                    ? AppColors.success
                                    : AppColors.gray400,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Evidence upload ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Foto Bukti',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray800,
                              ),
                            ),
                            Text(
                              '${_evidencePaths.length}/5 foto',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _EvidenceGrid(
                          paths: _evidencePaths,
                          onAdd: _evidencePaths.length < 5
                              ? _addEvidence
                              : null,
                          onRemove: (index) =>
                              setState(() => _evidencePaths.removeAt(index)),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Submit button ──
              _SubmitBar(
                isSubmitting: _isSubmitting,
                onSubmit: _submitClaim,
              ),
            ],
          );
        },
      ),
    );
  }

  void _addEvidence() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _simulateAddPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _simulateAddPhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Simulate adding a photo (replace with real image picker).
  void _simulateAddPhoto() {
    if (_evidencePaths.length >= 5) return;
    setState(() {
      _evidencePaths.add('evidence_${_evidencePaths.length + 1}.jpg');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto berhasil ditambahkan'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitClaim() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final success = await context.read<InsuranceProvider>().fileClaim(
          policyId: _selectedPolicyId!,
          claimType: _claimType,
          description: _descriptionController.text,
          evidenceUrls: _evidencePaths,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<InsuranceProvider>().errorMessage ??
                  'Gagal mengajukan klaim',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Klaim Berhasil Diajukan!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tim kami akan memproses klaim kamu dalam 3-5 hari kerja. Pantau statusnya di menu Klaim.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/insurance/my');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Lihat Status Klaim'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Claim type selection chip.
class _ClaimTypeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ClaimTypeChip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.blueLight : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.gray300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.blue : AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Evidence photo grid with add/remove.
class _EvidenceGrid extends StatelessWidget {
  final List<String> paths;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;

  const _EvidenceGrid({
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Existing photos
        ...paths.asMap().entries.map(
              (entry) => _EvidenceTile(
                index: entry.key,
                label: 'Foto ${entry.key + 1}',
                onRemove: () => onRemove(entry.key),
              ),
            ),

        // Add button
        if (onAdd != null) _AddEvidenceButton(onTap: onAdd!),
      ],
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final int index;
  final String label;
  final VoidCallback onRemove;

  const _EvidenceTile({
    required this.index,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_rounded,
                  color: AppColors.blue, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddEvidenceButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddEvidenceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gray300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded,
                color: AppColors.gray400, size: 28),
            const SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.gray500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Submit button bar.
class _SubmitBar extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Ajukan Klaim',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
