import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingLine {
  DrawingLine({
    required this.points,
    required this.color,
    required this.width,
  });
  final List<Offset> points;
  final Color color;
  final double width;
}

class TextOverlay {
  TextOverlay({
    required this.id,
    required this.text,
    required this.color,
    required this.position,
    this.fontSize = 24.0,
  });
  final String id;
  String text;
  Color color;
  Offset position;
  double fontSize;
}

class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({
    super.key,
    required this.imageBytes,
    required this.imageName,
  });

  final Uint8List imageBytes;
  final String imageName;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  final GlobalKey _globalKey = GlobalKey();
  
  double _imageAspectRatio = 1.0;
  bool _initialized = false;

  // Drawing state
  final List<DrawingLine> _lines = [];
  DrawingLine? _currentLine;
  bool _isDrawingMode = true;
  Color _currentColor = const Color(0xFFEF4444); // Red
  double _currentBrushWidth = 6.0;

  // Text state
  final List<TextOverlay> _textOverlays = [];
  String? _selectedOverlayId;

  // Palette colors matching modern styling
  final List<Color> _colors = const [
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFFACC15), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
  ];

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  void _loadImageDimensions() {
    final image = Image.memory(widget.imageBytes);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageAspectRatio = info.image.width / info.image.height;
            _initialized = true;
          });
        }
      }),
    );
  }

  void _showTextDialog({TextOverlay? existingOverlay}) {
    final textCtrl = TextEditingController(text: existingOverlay?.text ?? '');
    Color selectedColor = existingOverlay?.color ?? Colors.white;
    double selectedFontSize = existingOverlay?.fontSize ?? 26.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xEE0B0F19), // Slate 950 glassmorphic
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20, 20, 20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        existingOverlay == null ? 'Добавить текст' : 'Изменить текст',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (textCtrl.text.trim().isNotEmpty) {
                            Navigator.pop(context, {
                              'text': textCtrl.text.trim(),
                              'color': selectedColor,
                              'fontSize': selectedFontSize,
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Готово',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: TextField(
                        controller: textCtrl,
                        autofocus: true,
                        maxLines: null,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedColor,
                          fontSize: selectedFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Введите текст...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.format_size_rounded, color: Colors.white, size: 20),
                      Expanded(
                        child: Slider(
                          value: selectedFontSize,
                          min: 16.0,
                          max: 60.0,
                          activeColor: const Color(0xFF3B82F6),
                          inactiveColor: Colors.white.withOpacity(0.15),
                          onChanged: (val) {
                            setModalState(() => selectedFontSize = val);
                          },
                        ),
                      ),
                      Text(
                        '${selectedFontSize.toInt()} px',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _colors.map((c) {
                        final isSelected = c.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = c),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                                width: isSelected ? 3 : 1.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && mounted) {
        setState(() {
          if (existingOverlay != null) {
            existingOverlay.text = result['text'];
            existingOverlay.color = result['color'];
            existingOverlay.fontSize = result['fontSize'];
          } else {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            // Put initially in center
            _textOverlays.add(
              TextOverlay(
                id: id,
                text: result['text'],
                color: result['color'],
                fontSize: result['fontSize'],
                position: const Offset(80, 120),
              ),
            );
            _selectedOverlayId = id;
          }
        });
      }
    });
  }

  Future<void> _exportImage() async {
    try {
      setState(() {
        _selectedOverlayId = null;
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final pngBytes = byteData.buffer.asUint8List();
      if (mounted) {
        Navigator.pop(context, pngBytes);
      }
    } catch (e) {
      debugPrint('Export image error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Premium deep space dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Редактор фото',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_lines.isNotEmpty || _textOverlays.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo_rounded, color: Colors.white),
              tooltip: 'Отменить действие',
              onPressed: () {
                setState(() {
                  if (_lines.isNotEmpty) {
                    _lines.removeLast();
                  } else if (_textOverlays.isNotEmpty) {
                    _textOverlays.removeLast();
                  }
                });
              },
            ),
          if (_lines.isNotEmpty || _textOverlays.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: 'Очистить всё',
              onPressed: () {
                setState(() {
                  _lines.clear();
                  _textOverlays.clear();
                });
              },
            ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              onPressed: _exportImage,
              child: const Text(
                'Готово',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: !_initialized
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
                strokeWidth: 2,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Perfect fit for aspect ratio
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            
                            double canvasWidth;
                            double canvasHeight;
                            if (w / h > _imageAspectRatio) {
                              canvasHeight = h;
                              canvasWidth = h * _imageAspectRatio;
                            } else {
                              canvasWidth = w;
                              canvasHeight = w / _imageAspectRatio;
                            }

                            return Container(
                              width: canvasWidth,
                              height: canvasHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  // Capturing container
                                  RepaintBoundary(
                                    key: _globalKey,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(
                                          widget.imageBytes,
                                          fit: BoxFit.fill,
                                        ),
                                        // Drawing Canvas
                                        CustomPaint(
                                          painter: CanvasPainter(lines: _lines),
                                          size: Size(canvasWidth, canvasHeight),
                                        ),
                                        // Text Overlays
                                        ..._textOverlays.map((overlay) {
                                          final isSelected =
                                              _selectedOverlayId == overlay.id;
                                          return Positioned(
                                            left: overlay.position.dx,
                                            top: overlay.position.dy,
                                            child: GestureDetector(
                                              onPanUpdate: (details) {
                                                setState(() {
                                                  _selectedOverlayId = overlay.id;
                                                  overlay.position = Offset(
                                                    (overlay.position.dx + details.delta.dx)
                                                        .clamp(0.0, canvasWidth - 60),
                                                    (overlay.position.dy + details.delta.dy)
                                                        .clamp(0.0, canvasHeight - 30),
                                                  );
                                                });
                                              },
                                              onTap: () {
                                                setState(() {
                                                  _selectedOverlayId =
                                                      isSelected ? null : overlay.id;
                                                });
                                              },
                                              onDoubleTap: () => _showTextDialog(
                                                existingOverlay: overlay,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: isSelected
                                                      ? Border.all(
                                                          color: const Color(0xFF3B82F6),
                                                          width: 1.5,
                                                        )
                                                      : null,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  color: Colors.black.withOpacity(0.35),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      overlay.text,
                                                      style: TextStyle(
                                                        color: overlay.color,
                                                        fontSize: overlay.fontSize,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (isSelected) ...[
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            _textOverlays.removeWhere(
                                                              (o) => o.id == overlay.id,
                                                            );
                                                            _selectedOverlayId = null;
                                                          });
                                                        },
                                                        child: const Icon(
                                                          Icons.close_rounded,
                                                          color: Colors.redAccent,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  // Gesture interceptor overlay when drawing
                                  if (_isDrawingMode)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onPanStart: (details) {
                                          setState(() {
                                            _selectedOverlayId = null;
                                            _currentLine = DrawingLine(
                                              points: [details.localPosition],
                                              color: _currentColor,
                                              width: _currentBrushWidth,
                                            );
                                            _lines.add(_currentLine!);
                                          });
                                        },
                                        onPanUpdate: (details) {
                                          if (_currentLine == null) return;
                                          setState(() {
                                            _currentLine!.points
                                                .add(details.localPosition);
                                          });
                                        },
                                        onPanEnd: (_) {
                                          setState(() {
                                            _currentLine = null;
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                  _buildControlsUI(),
                ],
              ),
    );
  }

  Widget _buildControlsUI() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brush Size Slider (shown only when drawing)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isDrawingMode
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
                        Expanded(
                          child: Slider(
                            value: _currentBrushWidth,
                            min: 2.0,
                            max: 18.0,
                            activeColor: const Color(0xFF3B82F6),
                            inactiveColor: Colors.white.withOpacity(0.1),
                            onChanged: (val) {
                              setState(() => _currentBrushWidth = val);
                            },
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: _currentBrushWidth * 0.7,
                              height: _currentBrushWidth * 0.7,
                              decoration: BoxDecoration(
                                color: _currentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Row(
            children: [
              // Draw mode toggle
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: _isDrawingMode
                      ? const Color(0xFF3B82F6).withOpacity(0.2)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _isDrawingMode
                          ? const Color(0xFF3B82F6).withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.edit_rounded,
                  color: _isDrawingMode ? const Color(0xFF3B82F6) : Colors.white70,
                ),
                tooltip: 'Рисовать',
                onPressed: () {
                  setState(() {
                    _isDrawingMode = true;
                    _selectedOverlayId = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              // Add Text button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: !_isDrawingMode
                      ? const Color(0xFF3B82F6).withOpacity(0.2)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.text_fields, color: Colors.white70),
                tooltip: 'Добавить текст',
                onPressed: () {
                  setState(() {
                    _isDrawingMode = false;
                  });
                  _showTextDialog();
                },
              ),
              if (_isDrawingMode) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _colors.map((c) {
                        final isSelected = c.value == _currentColor.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentColor = c);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  CanvasPainter({required this.lines});
  final List<DrawingLine> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      paint.color = line.color;
      paint.strokeWidth = line.width;
      if (line.points.length > 1) {
        for (int i = 0; i < line.points.length - 1; i++) {
          canvas.drawLine(line.points[i], line.points[i + 1], paint);
        }
      } else if (line.points.isNotEmpty) {
        canvas.drawCircle(
          line.points.first,
          line.width / 2,
          paint
            ..style = PaintingStyle.fill
            ..color = line.color,
        );
        paint.style = PaintingStyle.stroke; // reset
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}
