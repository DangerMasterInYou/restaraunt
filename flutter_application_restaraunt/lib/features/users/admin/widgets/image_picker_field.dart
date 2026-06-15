import 'package:flutter/material.dart';

import '/api_config.dart';
import '/core/services/image_upload.dart';

class ImagePickerField extends StatefulWidget {
  final String? imageUrl;
  final ValueChanged<String> onChanged;

  const ImagePickerField({
    super.key,
    required this.imageUrl,
    required this.onChanged,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  late String? _url = widget.imageUrl;
  bool _loading = false;

  String _fullUrl(String url) =>
      url.startsWith('http') ? url : '${ApiConfig.apiSiteUrl}$url';

  Future<void> _pick() async {
    setState(() => _loading = true);
    try {
      final url = await ImageUploadService.pickAndUpload();
      if (url != null) {
        setState(() => _url = url);
        widget.onChanged(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _url != null && _url!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading ? null : _pick,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 96,
              height: 96,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(_fullUrl(_url!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image))
                  else
                    Icon(Icons.add_a_photo,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  if (_loading)
                    const ColoredBox(
                      color: Color(0x66000000),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (hasImage)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
