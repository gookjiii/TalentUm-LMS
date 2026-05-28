import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:school_world/src/features/chat/presentation/widgets/chat_bubble/chat_bubble.dart';
import 'package:school_world/src/features/chat/domain/models/chat_attachment.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_input/chat_input_previews.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    this.replyingTo,
    required this.onCancelReply,
    this.editingMessage,
    required this.onCancelEditing,
    this.pendingAttachment,
    required this.onCancelAttachment,
    this.onCreatePoll,
    this.isUploading = false,
    required this.className,
    this.onTypingChanged,
    this.onCamera,
    this.onAudioSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final Message? replyingTo;
  final VoidCallback onCancelReply;
  final Message? editingMessage;
  final VoidCallback onCancelEditing;
  final PickedChatAttachment? pendingAttachment;
  final VoidCallback onCancelAttachment;
  final VoidCallback? onCreatePoll;
  final bool isUploading;
  final String className;
  final ValueChanged<bool>? onTypingChanged;
  final VoidCallback? onCamera;
  final void Function(String path, Duration duration)? onAudioSend;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final FocusNode _focusNode = FocusNode();
  Timer? _typingTimer;
  bool _isTyping = false;

  // Recording state
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordStartTime;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;

  // Recorded audio review state
  String? _recordedAudioPath;
  Duration? _recordedAudioDuration;
  final audioplayers.AudioPlayer _audioPlayer = audioplayers.AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _typingTimer?.cancel();
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _onTextChanged() {
    if (widget.controller.text.trim().isNotEmpty) {
      if (!_isTyping) {
        _isTyping = true;
        widget.onTypingChanged?.call(true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (_isTyping) {
          _isTyping = false;
          widget.onTypingChanged?.call(false);
        }
      });
    } else {
      if (_isTyping) {
        _isTyping = false;
        _typingTimer?.cancel();
        widget.onTypingChanged?.call(false);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String? path;
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        await _audioRecorder.start(const RecordConfig(), path: path ?? '');

        setState(() {
          _isRecording = true;
          _recordStartTime = DateTime.now();
          _recordDuration = Duration.zero;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration = DateTime.now().difference(_recordStartTime!);
          });
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    try {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();

      final finalDuration = _recordDuration;
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
      });

      if (!cancel && path != null && widget.onAudioSend != null) {
        if (finalDuration.inSeconds >= 1) {
          setState(() {
            _recordedAudioPath = path;
            _recordedAudioDuration = finalDuration;
          });
        }
      } else if (path != null && !kIsWeb) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Stop recording error: $e');
    }
  }

  void _discardRecordedAudio() {
    if (_recordedAudioPath != null && !kIsWeb) {
      final file = File(_recordedAudioPath!);
      if (file.existsSync()) file.deleteSync();
    }
    setState(() {
      _recordedAudioPath = null;
      _recordedAudioDuration = null;
      _isPlayingAudio = false;
    });
    _audioPlayer.stop();
  }

  void _sendRecordedAudio() {
    if (_recordedAudioPath != null && _recordedAudioDuration != null) {
      widget.onAudioSend!(_recordedAudioPath!, _recordedAudioDuration!);
      setState(() {
        _recordedAudioPath = null;
        _recordedAudioDuration = null;
        _isPlayingAudio = false;
      });
    }
  }

  Future<void> _togglePlayRecordedAudio() async {
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() => _isPlayingAudio = false);
    } else {
      if (_recordedAudioPath != null) {
        await _audioPlayer.play(
          audioplayers.DeviceFileSource(_recordedAudioPath!),
        );
        setState(() => _isPlayingAudio = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFocused = _focusNode.hasFocus;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final isEditing = widget.editingMessage != null;

    if (_isRecording) {
      return _buildRecordingUI(theme);
    }

    if (_recordedAudioPath != null) {
      return _buildRecordedAudioPreviewUI(theme);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        isMobile ? 8 : 12,
        isMobile ? 12 : 16,
        (isMobile ? 12 : 16) + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
          border: Border.all(
            color: isFocused
                ? const Color(0xFF2563EB).withOpacity(0.5)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE4ECFC)),
            width: isFocused ? 1.5 : 1.5,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: const Color(
                      0xFF2563EB,
                    ).withOpacity(isDark ? 0.15 : 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: widget.replyingTo == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: ReplyPreview(
                        message: widget.replyingTo!,
                        onCancel: widget.onCancelReply,
                      ),
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: !isEditing
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: EditPreview(
                        message: widget.editingMessage!,
                        onCancel: widget.onCancelEditing,
                      ),
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: widget.pendingAttachment == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: PendingAttachmentPreview(
                        attachment: widget.pendingAttachment!,
                        onCancel: widget.onCancelAttachment,
                      ),
                    ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: isEditing ? null : widget.onAttachment,
                  icon: Icon(
                    isMobile
                        ? Icons.attach_file_rounded
                        : Icons.add_circle_outline_rounded,
                    color: isEditing
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
                        : theme.colorScheme.primary,
                  ),
                  tooltip: 'Прикрепить',
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  constraints: isMobile
                      ? const BoxConstraints(minWidth: 40, minHeight: 40)
                      : null,
                ),
                if (isMobile && widget.onCamera != null && !isEditing)
                  IconButton(
                    onPressed: widget.onCamera,
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Камера',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                if (widget.onCreatePoll != null && !isEditing)
                  IconButton(
                    onPressed: widget.onCreatePoll,
                    icon: Icon(
                      Icons.poll_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Опрос',
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    constraints: isMobile
                        ? const BoxConstraints(minWidth: 40, minHeight: 40)
                        : null,
                  ),
                Expanded(
                  child: Focus(
                    onKeyEvent: isMobile
                        ? null
                        : (node, event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              final canSend =
                                  (widget.controller.text.trim().isNotEmpty ||
                                      widget.pendingAttachment != null) &&
                                  !widget.isUploading;
                              if (canSend) widget.onSend();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.4,
                        fontSize: isMobile ? 15 : 16,
                      ),
                      decoration: InputDecoration(
                        hintText: isMobile
                            ? 'Сообщение'
                            : (isEditing
                                  ? 'Изменить сообщение'
                                  : 'Написать в ${widget.className}...'),
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.6,
                          ),
                          fontSize: isMobile ? 15 : 16,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, child) {
                    final hasText = value.text.trim().isNotEmpty;
                    final hasAttachment = widget.pendingAttachment != null;
                    final canSend =
                        (hasText || hasAttachment) && !widget.isUploading;

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        final isSend =
                            child.key == const ValueKey('send') ||
                            child.key == const ValueKey('mic');
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: isSend ? Curves.elasticOut : Curves.easeOut,
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: !canSend
                          ? GestureDetector(
                              key: const ValueKey('mic'),
                              onLongPress: isEditing ? null : _startRecording,
                              onLongPressEnd: isEditing
                                  ? null
                                  : (details) => _stopRecording(),
                              onLongPressCancel: isEditing
                                  ? null
                                  : () => _stopRecording(cancel: true),
                              child: IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Удерживайте для записи голоса',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.mic_rounded),
                                color: theme.colorScheme.primary,
                                padding: EdgeInsets.all(isMobile ? 8 : 10),
                                constraints: isMobile
                                    ? const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      )
                                    : null,
                              ),
                            )
                          : Padding(
                              key: const ValueKey('send'),
                              padding: const EdgeInsets.all(2),
                              child: _GradientSendButton(
                                onTap: widget.onSend,
                                isUploading: widget.isUploading,
                                isEditing: isEditing,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingUI(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const _PulseRedDot(),
            const SizedBox(width: 12),
            Text(
              'Запись: ${_recordDuration.inMinutes}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _stopRecording(cancel: true),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Colors.red,
              ),
              label: const Text('Отмена', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 8),
            const Text(
              'Отпустите для просмотра',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordedAudioPreviewUI(ThemeData theme) {
    final duration = _recordedAudioDuration ?? Duration.zero;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _togglePlayRecordedAudio,
              icon: Icon(
                _isPlayingAudio
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _discardRecordedAudio,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _GradientSendButton(
                onTap: _sendRecordedAudio,
                isUploading: widget.isUploading,
                isEditing: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseRedDot extends StatefulWidget {
  const _PulseRedDot();
  @override
  State<_PulseRedDot> createState() => _PulseRedDotState();
}

class _PulseRedDotState extends State<_PulseRedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _GradientSendButton extends StatefulWidget {
  const _GradientSendButton({
    required this.onTap,
    required this.isUploading,
    required this.isEditing,
  });
  final VoidCallback onTap;
  final bool isUploading;
  final bool isEditing;

  @override
  State<_GradientSendButton> createState() => _GradientSendButtonState();
}

class _GradientSendButtonState extends State<_GradientSendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: widget.isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    widget.isEditing ? Icons.done_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
