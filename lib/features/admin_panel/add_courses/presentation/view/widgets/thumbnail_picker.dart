// widgets/thumbnail_picker.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThumbnailPicker extends StatefulWidget {
  final TextEditingController ctrl;
  const ThumbnailPicker({super.key, required this.ctrl});

  @override
  State<ThumbnailPicker> createState() => _ThumbnailPickerState();
}

class _ThumbnailPickerState extends State<ThumbnailPicker> {
  bool get _hasUrl => widget.ctrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasUrl) ...[
          _PreviewImage(url: widget.ctrl.text),
          const SizedBox(height: 10),
        ],
        _PickerButtons(
          onGalleryTap: _pickFromGallery,
          onUrlTap: _enterUrl,
        ),
        if (_hasUrl) ...[
          const SizedBox(height: 10),
          _UrlField(
            ctrl: widget.ctrl,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() => widget.ctrl.clear()),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last;
      final fileName =
          'thumbnails/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('course-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext'),
          );

      final url = Supabase.instance.client.storage
          .from('course-images')
          .getPublicUrl(fileName);

      if (mounted) setState(() => widget.ctrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _enterUrl() {
    setState(() {
      if (widget.ctrl.text.isEmpty) widget.ctrl.text = 'https://';
    });
  }
}

// ─────────────────────────────────────────────
// Preview image
// ─────────────────────────────────────────────
class _PreviewImage extends StatelessWidget {
  final String url;
  const _PreviewImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 140,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: const Center(
            child: Icon(Icons.broken_image_rounded,
                color: Colors.white54, size: 40),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Gallery / URL buttons row
// ─────────────────────────────────────────────
class _PickerButtons extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onUrlTap;

  const _PickerButtons({
    required this.onGalleryTap,
    required this.onUrlTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PickerButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            color: AppColors.primary,
            bgColor: AppColors.primary.withOpacity(0.08),
            borderColor: AppColors.primary.withOpacity(0.3),
            onTap: onGalleryTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PickerButton(
            icon: Icons.link_rounded,
            label: 'URL',
            color: AppColors.textSecondary,
            bgColor: AppColors.surfaceVariant,
            borderColor: AppColors.cardBorder,
            onTap: onUrlTap,
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// URL text field with clear button
// ─────────────────────────────────────────────
class _UrlField extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _UrlField({
    required this.ctrl,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Thumbnail URL',
        prefixIcon: const Icon(Icons.image_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear_rounded, color: AppColors.textHint),
          onPressed: onClear,
        ),
      ),
    );
  }
}