import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/community_provider.dart';
import '../widgets/category_tag.dart';

/// Create post page with text input, photo picker, category, and visibility.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'tips';
  String _selectedVisibility = 'all';
  final List<String> _imageUrls = [];
  bool _isSubmitting = false;
  bool _showPreview = false;

  static const int _maxChars = 500;
  static const int _maxImages = 3;

  static const List<Map<String, String>> _categories = [
    {'value': 'tips', 'label': 'Tips'},
    {'value': 'question', 'label': 'Pertanyaan'},
    {'value': 'complaint', 'label': 'Keluhan'},
    {'value': 'info', 'label': 'Info Zona'},
    {'value': 'advocacy', 'label': 'Advokasi'},
  ];

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi postingan tidak boleh kosong'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<CommunityProvider>();
    final success = await provider.createPost(
      content: content,
      category: _selectedCategory,
      visibility: _selectedVisibility,
      imageUrls: _imageUrls,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postingan berhasil dibuat! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal membuat postingan'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _addImage() {
    if (_imageUrls.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal $_maxImages foto'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Show options: Camera or Gallery
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _mockAddImage('kamera');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _mockAddImage('galeri');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mockAddImage(String source) {
    // In real app, use image_picker. For now, add mock URL.
    setState(() {
      _imageUrls.add(
        'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/300',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Foto dari $source ditambahkan'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentLength = _contentController.text.length;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Buat Post'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Preview toggle
          TextButton(
            onPressed: () => setState(() => _showPreview = !_showPreview),
            child: Text(
              _showPreview ? 'Edit' : 'Preview',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final contentLength = _contentController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Text input ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _contentController,
                  maxLength: _maxChars,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Apa yang ingin kamu bagikan?',
                    hintStyle: TextStyle(color: AppColors.gray400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$contentLength/$_maxChars',
                      style: TextStyle(
                        fontSize: 12,
                        color: contentLength > _maxChars * 0.9
                            ? AppColors.danger
                            : AppColors.gray400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Photo picker ──
          Text(
            'Foto (opsional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ..._imageUrls.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          entry.value,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.gray200,
                            child: const Icon(Icons.image, color: AppColors.gray400),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_imageUrls.length < _maxImages)
                GestureDetector(
                  onTap: _addImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gray300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: AppColors.gray500, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '${_imageUrls.length}/$_maxImages',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Category selector ──
          Text(
            'Kategori',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['value']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBg : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.gray600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Visibility ──
          Text(
            'Visibilitas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _VisibilityOption(
                value: 'zone',
                groupValue: _selectedVisibility,
                label: 'Zona Saya',
                icon: Icons.location_on,
                onChanged: (v) => setState(() => _selectedVisibility = v!),
              ),
              const SizedBox(width: 12),
              _VisibilityOption(
                value: 'all',
                groupValue: _selectedVisibility,
                label: 'Semua',
                icon: Icons.public,
                onChanged: (v) => setState(() => _selectedVisibility = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryBg,
                      child: Text(
                        'K',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kamu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Baru saja',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Content
                Text(
                  _contentController.text.isEmpty
                      ? '(Belum ada isi)'
                      : _contentController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: _contentController.text.isEmpty
                        ? AppColors.gray400
                        : AppColors.gray800,
                    height: 1.5,
                  ),
                ),
                if (_imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: _imageUrls
                        .map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                CategoryTag(category: _selectedCategory, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _VisibilityOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBg : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.gray300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.gray500,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
