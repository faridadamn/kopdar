import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../config/theme.dart';
import '../providers/profile_provider.dart';
import '../widgets/document_tile.dart';

/// Documents page: SIM, STNK, SKCK, KTP management.
class DocumentPage extends StatefulWidget {
  const DocumentPage({super.key});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchDocuments();
    });
  }

  static const _requiredDocs = [
    _DocInfo(
      type: 'sim',
      title: 'SIM (Surat Izin Mengemudi)',
      description: 'Wajib untuk driver kendaraan bermotor',
      emoji: '🪪',
      required: true,
    ),
    _DocInfo(
      type: 'stnk',
      title: 'STNK (Surat Tanda Nomor Kendaraan)',
      description: 'Bukti kepemilikan kendaraan yang sah',
      emoji: '📋',
      required: true,
    ),
    _DocInfo(
      type: 'skck',
      title: 'SKCK',
      description: 'Surat Keterangan Catatan Kepolisian',
      emoji: '📜',
      required: false,
    ),
    _DocInfo(
      type: 'ktp',
      title: 'KTP',
      description: 'Kartu Tanda Penduduk',
      emoji: '🆔',
      required: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('📄 Dokumen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isDocumentLoading && provider.documents.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchDocuments,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Status summary ──
                _StatusSummary(
                  total: _requiredDocs.length,
                  verified: provider.documents
                      .where((d) => d.isVerified)
                      .length,
                ),
                const SizedBox(height: 16),

                // ── Info banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('i️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dokumen yang sudah diverifikasi tidak dapat diubah. Hubungi admin jika ada kesalahan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Document list ──
                Text(
                  'Dokumen yang Dibutuhkan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                ..._requiredDocs.map((docInfo) {
                  final existing = provider.documents
                      .where((d) => d.type == docInfo.type)
                      .firstOrNull;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DocumentSection(
                      docInfo: docInfo,
                      existing: existing,
                      onUpload: () =>
                          _showUploadSheet(context, provider, docInfo.type),
                      onDelete: existing != null
                          ? () => _confirmDelete(
                              context, provider, existing.id)
                          : null,
                      onView: existing?.fileUrl != null
                          ? () {
                              // TODO: Open document viewer
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Viewer dokumen - Segera hadir!'),
                                ),
                              );
                            }
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // ── Upload tips ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips Upload Dokumen',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _TipItem(
                          text: 'Foto harus jelas dan tidak buram'),
                      _TipItem(
                          text: 'Seluruh dokumen harus terlihat'),
                      _TipItem(
                          text: 'Format: JPG, PNG, atau PDF'),
                      _TipItem(
                          text: 'Ukuran maksimal 5 MB per file'),
                      _TipItem(
                          text: 'Pastikan data sesuai dengan identitas asli'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUploadSheet(
      BuildContext context, ProfileProvider provider, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload ${type.toUpperCase()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil Foto'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1200,
                    imageQuality: 90,
                  );
                  if (image != null && mounted) {
                    final success = await provider.uploadDocument(
                      type: type,
                      filePath: image.path,
                      fileName: image.name,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${type.toUpperCase()} berhasil diupload！'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    imageQuality: 90,
                  );
                  if (image != null && mounted) {
                    final success = await provider.uploadDocument(
                      type: type,
                      filePath: image.path,
                      fileName: image.name,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${type.toUpperCase()} berhasil diupload！'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: const Text('Pilih File (PDF/Gambar)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                  );
                  if (result != null && result.files.single.path != null && mounted) {
                    final file = result.files.single;
                    final success = await provider.uploadDocument(
                      type: type,
                      filePath: file.path!,
                      fileName: file.name,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${type.toUpperCase()} berhasil diupload！'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ProfileProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen?'),
        content: const Text(
            'Dokumen akan dihapus. Anda perlu upload ulang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteDocument(id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dokumen dihapus.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
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

/// Status summary showing verified count.
class _StatusSummary extends StatelessWidget {
  final int total;
  final int verified;

  const _StatusSummary({required this.total, required this.verified});

  @override
  Widget build(BuildContext context) {
    final isComplete = verified >= total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [AppColors.success, const Color(0xFF388E3C)]
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            isComplete ? '✅' : '📄',
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 10),
          Text(
            isComplete
                ? 'Semua dokumen lengkap!'
                : '$verified dari $total dokumen terverifikasi',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? verified / total : 0,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Document section with upload/view actions.
class _DocumentSection extends StatelessWidget {
  final _DocInfo docInfo;
  final dynamic existing; // DocumentModel?
  final VoidCallback? onUpload;
  final VoidCallback? onDelete;
  final VoidCallback? onView;

  const _DocumentSection({
    required this.docInfo,
    this.existing,
    this.onUpload,
    this.onDelete,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (existing != null) {
      return DocumentTile(
        document: existing,
        onUpload: onUpload,
        onDelete: onDelete,
        onView: onView,
      );
    }

    // Empty state - not yet uploaded
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: docInfo.required
              ? AppColors.warning.withOpacity(0.4)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(docInfo.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      docInfo.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.gray800,
                      ),
                    ),
                    if (docInfo.required) ...[
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  docInfo.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
            label: const Text('Upload'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocInfo {
  final String type;
  final String title;
  final String description;
  final String emoji;
  final bool required;

  const _DocInfo({
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.required,
  });
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: AppColors.gray400)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
