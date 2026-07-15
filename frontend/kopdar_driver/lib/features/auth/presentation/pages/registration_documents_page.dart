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
  final _picker = ImagePicker();
  File? _ktp;
  File? _selfie;
  File? _stnk;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final draft = context.read<RegistrationDraftProvider>();
      _ktp = draft.ktpPhoto;
      _selfie = draft.selfiePhoto;
      _stnk = draft.stnkPhoto;
      _initialized = true;
    }
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

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;

    setState(() {
      final file = File(image.path);
      if (type == 'ktp') _ktp = file;
      if (type == 'selfie') _selfie = file;
      if (type == 'stnk') _stnk = file;
    });
  }

  void _submit() {
    if (_ktp == null || _selfie == null || _stnk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KTP, selfie, dan STNK wajib dilengkapi.')),
      );
      return;
    }

    context.read<RegistrationDraftProvider>().setDocuments(
          ktp: _ktp,
          selfie: _selfie,
          stnk: _stnk,
        );
    context.push('/register/platforms');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Dokumen Verifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const LinearProgressIndicator(value: 0.6),
          const SizedBox(height: 24),
          Text('Lengkapi dokumen wajib',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Pastikan foto jelas, tidak terpotong, dan dapat dibaca.'),
          const SizedBox(height: 24),
          _DocumentTile(
            title: 'Foto KTP',
            file: _ktp,
            onTap: () => _choose('ktp'),
          ),
          const SizedBox(height: 12),
          _DocumentTile(
            title: 'Selfie dengan KTP',
            file: _selfie,
            onTap: () => _choose('selfie'),
          ),
          const SizedBox(height: 12),
          _DocumentTile(
            title: 'Foto STNK',
            file: _stnk,
            onTap: () => _choose('stnk'),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: const Text('Lanjut')),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final File? file;
  final VoidCallback onTap;

  const _DocumentTile({
    required this.title,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: file == null ? AppColors.gray300 : AppColors.primary,
        ),
      ),
      leading: Icon(
        file == null ? Icons.upload_file_outlined : Icons.check_circle,
        color: file == null ? AppColors.gray600 : AppColors.primary,
      ),
      title: Text(title),
      subtitle: Text(
        file == null ? 'Belum dipilih' : file!.uri.pathSegments.last,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
