import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_bubble/chat_bubble.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import 'package:school_world/main.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.currentUserId,
    required this.resolveUser,
    required this.chatController,
    required this.textMessageBuilder,
    required this.imageMessageBuilder,
    required this.fileMessageBuilder,
    this.audioMessageBuilder,
    required this.onImageTap,
    required this.onMessageLongPress,
    required this.onMessageSwipe,
  });

  final String currentUserId;
  final ResolveUserCallback resolveUser;
  final FirebaseChatController chatController;
  final Widget Function(
    BuildContext,
    TextMessage,
    int, {
    required bool isSentByMe,
    MessageGroupStatus? groupStatus,
  })
  textMessageBuilder;
  final Widget Function(
    BuildContext,
    ImageMessage,
    int, {
    required bool isSentByMe,
    MessageGroupStatus? groupStatus,
  })
  imageMessageBuilder;
  final Widget Function(
    BuildContext,
    FileMessage,
    int, {
    required bool isSentByMe,
    MessageGroupStatus? groupStatus,
  })
  fileMessageBuilder;
  final Widget Function(
    BuildContext,
    FileMessage,
    int, {
    required bool isSentByMe,
    MessageGroupStatus? groupStatus,
  })?
  audioMessageBuilder;
  final void Function(ImageMessage) onImageTap;
  final void Function(Message, {Offset? position}) onMessageLongPress;
  final void Function(Message) onMessageSwipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0E1621) : const Color(0xFFE7EBF3);
    final dotColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.06);

    return ListenableBuilder(
      listenable: chatController,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: _AuroraBackground(bgColor: bgColor, dotColor: dotColor),
              ),
            ),
            Positioned.fill(
              child: Chat(
                currentUserId: currentUserId,
                resolveUser: resolveUser,
                chatController: chatController,
                theme: (isDark ? ChatTheme.dark() : ChatTheme.light()).copyWith(
                  colors: (isDark ? ChatTheme.dark() : ChatTheme.light()).colors
                      .copyWith(
                        primary: theme.colorScheme.primary,
                        onPrimary: theme.colorScheme.onPrimary,
                        surface: Colors.transparent,
                        onSurface: theme.colorScheme.onSurface,
                        surfaceContainer: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5FD),
                      ),
                ),
                builders: Builders(
                  chatAnimatedListBuilder: (context, itemBuilder) => ChatAnimatedList(
                    itemBuilder: itemBuilder,
                    reversed: true,
                    bottomPadding: 16,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    insertAnimationDuration: const Duration(milliseconds: 350),
                    bottomSliver: SliverToBoxAdapter(
                      child: _TypingIndicatorBuilder(
                        chatController: chatController,
                        currentUserId: currentUserId,
                        theme: theme,
                      ),
                    ),
                  ),
                  chatMessageBuilder:
                      (
                        context,
                        message,
                        index,
                        animation,
                        originalChild, {
                        isRemoved,
                        required isSentByMe,
                        groupStatus,
                      }) {
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );

                        Widget child = originalChild;
                        if (message is FileMessage) {
                          final isAudio =
                              message.metadata?['type'] == 'audio' ||
                              message.metadata?['attachmentType'] == 'audio';
                          if (isAudio && audioMessageBuilder != null) {
                            child = audioMessageBuilder!(
                              context,
                              message,
                              index,
                              isSentByMe: isSentByMe,
                              groupStatus: groupStatus,
                            );
                          }
                        }

                        return FadeTransition(
                          opacity: curvedAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(curvedAnimation),
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.98,
                                end: 1.0,
                              ).animate(curvedAnimation),
                              alignment: isSentByMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: VisibilityDetector(
                                key: Key('msg-visibility-${message.id}'),
                                onVisibilityChanged: (info) {
                                  if (info.visibleFraction > 0.1 && !isSentByMe) {
                                    final repo = AppScope.of(context).repository;
                                    final seenBy = List<String>.from(
                                      message.metadata?['seenBy'] ?? [],
                                    );
                                    if (!seenBy.contains(currentUserId)) {
                                      repo.markMessageAsSeen(
                                        chatController.roomId,
                                        message.id,
                                      );
                                    }
                                  }
                                },
                                child: SwipeTo(
                                  key: ValueKey(message.id),
                                  onRightSwipe: (details) {
                                    onMessageSwipe(message);
                                  },
                                  child: ChatMessage(
                                    message: message,
                                    index: index,
                                    animation: const AlwaysStoppedAnimation(
                                      1.0,
                                    ), // Disable internal animation
                                    isRemoved: isRemoved,
                                    groupStatus: groupStatus,
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                  textMessageBuilder: textMessageBuilder,
                  imageMessageBuilder: imageMessageBuilder,
                  fileMessageBuilder: fileMessageBuilder,
                  composerBuilder: (_) => const SizedBox.shrink(),
                ),
                onMessageTap:
                    (_, msg, {required int index, required TapUpDetails details}) {
                      if (msg is ImageMessage) onImageTap(msg);
                    },
                onMessageLongPress:
                    (
                      _,
                      msg, {
                      required int index,
                      required LongPressStartDetails details,
                    }) {
                      onMessageLongPress(msg, position: details.globalPosition);
                    },
                onEndReached: () => chatController.loadOlder(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypingIndicatorBuilder extends StatefulWidget {
  const _TypingIndicatorBuilder({
    required this.chatController,
    required this.currentUserId,
    required this.theme,
  });

  final FirebaseChatController chatController;
  final String currentUserId;
  final ThemeData theme;

  @override
  State<_TypingIndicatorBuilder> createState() => _TypingIndicatorBuilderState();
}

class _TypingIndicatorBuilderState extends State<_TypingIndicatorBuilder> {
  Stream<List<String>>? _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _TypingIndicatorBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatController.roomId != widget.chatController.roomId) {
      _initStream();
    }
  }

  void _initStream() {
    _stream = widget.chatController.typingUsersStream(widget.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _stream,
      builder: (context, snap) {
        final typing = snap.data ?? [];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: typing.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: widget.theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TypingIndicator(size: 4),
                            const SizedBox(width: 8),
                            Text(
                              typing.length == 1
                                  ? 'Печатает...'
                                  : '${typing.length} печатают...',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground({required this.bgColor, required this.dotColor});
  final Color bgColor;
  final Color dotColor;

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _DotGridPainter(
            bgColor: widget.bgColor,
            dotColor: widget.dotColor,
            animationValue: _ctrl.value,
          ),
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({
    required this.bgColor,
    required this.dotColor,
    required this.animationValue,
  });
  final Color bgColor;
  final Color dotColor;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Solid background fill
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    // 2. Animated fluid Aurora radial gradients
    final Paint glow1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF2563EB).withOpacity(0.06), // Primary Blue
              const Color(0xFF2563EB).withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width *
                    (0.3 + 0.3 * math.sin(animationValue * 2 * math.pi)),
                size.height *
                    (0.2 + 0.2 * math.cos(animationValue * 2 * math.pi)),
              ),
              radius: size.width * 0.9,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow1);

    final Paint glow2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF6366F1).withOpacity(0.05), // Indigo Purple
              const Color(0xFF6366F1).withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width *
                    (0.7 + 0.2 * math.cos(animationValue * 2 * math.pi + 1.2)),
                size.height *
                    (0.6 + 0.2 * math.sin(animationValue * 2 * math.pi + 1.2)),
              ),
              radius: size.width * 0.8,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow2);

    // 3. Static canvas dot-grid mesh
    final dotPaint = Paint()..color = dotColor;
    const spacing = 22.0;
    const radius = 1.2;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.bgColor != bgColor ||
      old.dotColor != dotColor ||
      old.animationValue != animationValue;
}
