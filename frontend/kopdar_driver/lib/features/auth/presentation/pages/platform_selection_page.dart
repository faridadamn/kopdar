import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../config/constants.dart';
import '../providers/registration_draft_provider.dart';

class PlatformSelectionPage extends StatefulWidget {
  const PlatformSelectionPage({super.key});

  @override
  State<PlatformSelectionPage> createState() => _PlatformSelectionPageState();
}

class _PlatformSelectionPageState extends State<PlatformSelectionPage> {
  final Set<String> _selected = {};
  final _other = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selected.addAll(context.read<RegistrationDraftProvider>().platforms);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _submit() {
    final other = _other.text.trim();
    if (other.isNotEmpty) _selected.add(other);
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu platform.')),
      );
      return;
    }
    context.read<RegistrationDraftProvider>().setPlatforms(_selected.toList());
    context.push('/register/bank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Aktif')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const LinearProgressIndicator(value: 0.8),
          const SizedBox(height: 24),
          Text(
            'Pilih platform yang aktif digunakan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...AppConstants.platforms.map(
            (platform) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(platform),
              value: _selected.contains(platform),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _selected.add(platform);
                } else {
                  _selected.remove(platform);
                }
              }),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _other,
            decoration: const InputDecoration(
              labelText: 'Platform lain (opsional)',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: const Text('Lanjut')),
        ],
      ),
    );
  }
}
