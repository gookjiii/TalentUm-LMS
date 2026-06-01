import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:school_world/src/features/chat/presentation/screens/photo_editor_screen.dart';
import '../utils/string_extensions.dart';

/// Full-screen image viewer with pinch-to-zoom and Telegram-style photo editing support.
class ImageViewer extends StatefulWidget {
  const ImageViewer({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  bool _isLoading = false;

  Future<void> _handleEdit() async {
    setState(() => _isLoading = true);

    try {
      final response = await Dio().get<List<int>>(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data!);
      
      setState(() => _isLoading = false);

      if (mounted) {
        final navigator = Navigator.of(context);
        
        final editedBytes = await navigator.push<Uint8List?>(
          MaterialPageRoute(
            builder: (context) => PhotoEditorScreen(
              imageBytes: bytes,
              imageName: 'edited_${DateTime.now().millisecondsSinceEpoch}.png',
            ),
          ),
        );
        
        if (editedBytes != null && mounted) {
          navigator.pop(editedBytes); // Close viewer and return edited bytes
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось загрузить фото для редактирования: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl.toDirectImageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 40,
            right: 16,
            child: Row(
              children: [
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                    tooltip: 'Редактировать',
                    onPressed: _handleEdit,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
