import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../providers/registration_draft_provider.dart';

class RegistrationDocumentsPage extends StatefulWidget {
  const RegistrationDocumentsPage({super.key});

  @override
  State<RegistrationDocumentsPage> createState() =>
      _RegistrationDocumentsPageState();
}

class _RegistrationDocumentsPageState extends State<RegistrationDocumentsPage> {
  final ImagePicker _picker = ImagePicker();
  File? _ktp;
  File? _selfie;
  File? _stnk;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final draft = context.read<RegistrationDraftProvider>();
    _ktp ??= draft.ktpPhoto;
    _selfie ??= draft.selfiePhoto;
    _stnk ??= draft.stnkPhoto;
  }

  Future<File?> _pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    return image == null ? null : File(image.path);
  }

  Future<void> _choose(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _pick(source);
    if (file == null || !mounted) return;
    setState(() {
      switch (type) {
        case 'ktp':
          _ktp = file;
          break;
        case 'selfie':
          _selfie = file;
          break;
        case 'stnk':
          _stnk = file;
          break;
      }
    });
  }

  Future<void> _submit() async {
    if (_ktp == null || _selfie == null || _stnk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KTP, selfie, dan STNK wajib dilengkapi.')),
      );
      return;
    }
    setState(() => _loading = true);
    context.read<RegistrationDraftProvider>().setDocuments(
          ktp: _ktp,
          selfie: _selfie,
          stnk: _stnk,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    context.push('/register/platforms');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Dokumen Verifikasi'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const LinearProgressIndicator(value: 0.6),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Lengkapi dokumen wajib',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Foto harus jelas, tidak terpotong, dan seluruh informasi dapat dibaca.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 24),
                  _DocumentTile(
                    title: 'Foto KTP',
                    subtitle: 'Foto bagian depan KTP',
                    file: _ktp,
                    onTap: () => _choose('ktp'),
                  ),
                  const SizedBox(height: 12),
                  _DocumentTile(
                    title: 'Selfie dengan KTP',
                    subtitle: 'Wajah dan KTP harus terlihat jelas',
                    file: _selfie,
                    onTap: () => _choose('selfie'),
                  ),
                  const SizedBox(height: 12),
                  _DocumentTile(
                    title: 'Foto STNK',
                    subtitle: 'Gunakan STNK kendaraan yang didaftarkan',
                    file: _stnk,
                    onTap: () => _choose('stnk'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Lanjut'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final File? file;
  final VoidCallback onTap;

  const _DocumentTile({
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: file == null ? AppColors.gray300 : AppColors.primary,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  file == null ? AppColors.gray100 : AppColors.primaryBg,
              child: Icon(
                file == null ? Icons.upload_file_outlined : Icons.check,
                color: file == null ? AppColors.gray600 : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    file?.path.split(Platform.pathSeparator).last ?? subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
