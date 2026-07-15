import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/registration_draft_provider.dart';

class BankInfoPage extends StatefulWidget {
  const BankInfoPage({super.key});

  @override
  State<BankInfoPage> createState() => _BankInfoPageState();
}

class _BankInfoPageState extends State<BankInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumber = TextEditingController();
  final _accountName = TextEditingController();
  String? _bank;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final draft = context.read<RegistrationDraftProvider>();
      _bank = draft.bankName.isEmpty ? null : draft.bankName;
      _accountNumber.text = draft.bankAccountNumber;
      _accountName.text = draft.bankAccountName;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _accountNumber.dispose();
    _accountName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _bank == null) return;

    final draft = context.read<RegistrationDraftProvider>();
    draft.setBankData(
      bankName: _bank!,
      accountNumber: _accountNumber.text.trim(),
      accountName: _accountName.text.trim(),
    );

    if (!draft.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data registrasi belum lengkap. Periksa data diri, kendaraan, dokumen, dan platform.'),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.submitDriverRegistration(
      fullName: draft.fullName,
      nik: draft.nik,
      dateOfBirth: draft.dateOfBirth!,
      address: draft.address,
      city: draft.city,
      province: draft.province,
      postalCode: draft.postalCode,
      vehicleType: draft.vehicleType,
      vehiclePlate: draft.vehiclePlate,
      vehicleYear: draft.vehicleYear,
      emergencyContactName: draft.emergencyContactName,
      emergencyContactPhone: draft.emergencyContactPhone,
      platforms: draft.platforms,
      ktpPhoto: draft.ktpPhoto!,
      selfiePhoto: draft.selfiePhoto!,
      stnkPhoto: draft.stnkPhoto!,
    );

    if (!mounted) return;
    if (success) {
      draft.clear();
      context.go('/waiting-verification');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Pendaftaran gagal dikirim.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().status == AuthStatus.loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Rekening Bank')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const LinearProgressIndicator(value: 1),
            const SizedBox(height: 24),
            Text(
              'Data pencairan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _bank,
              decoration: const InputDecoration(labelText: 'Bank / E-Wallet'),
              items: AppConstants.banks
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['code'],
                      child: Text(item['name'] ?? item['code'] ?? '-'),
                    ),
                  )
                  .toList(),
              onChanged: loading ? null : (value) => setState(() => _bank = value),
              validator: (value) => value == null ? 'Pilih bank' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nomor rekening'),
              validator: (v) => v == null || v.trim().length < 5 ? 'Nomor rekening tidak valid' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountName,
              decoration: const InputDecoration(labelText: 'Nama pemilik rekening'),
              validator: (v) => v == null || v.trim().length < 3 ? 'Nama pemilik wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: loading ? null : _submit,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(loading ? 'Mengirim...' : 'Kirim Pendaftaran'),
            ),
          ],
        ),
      ),
    );
  }
}
