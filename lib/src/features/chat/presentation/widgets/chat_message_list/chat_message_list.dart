import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_bubble/chat_bubble.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import 'package:school_world/src/theme.dart';
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

    final performanceMode = AppScope.of(context).appState.performanceMode;
    return ListenableBuilder(
      listenable: chatController,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: _AuroraBackground(
                  bgColor: bgColor,
                  dotColor: dotColor,
                  performanceMode: performanceMode,
                ),
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
                  scrollToBottomBuilder: (context, animation, onPressed) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12, right: 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.4 : 0.12,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onPressed();
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 28,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  emptyChatListBuilder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : SchoolColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.noMessagesYet,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.messageYourClass,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  chatAnimatedListBuilder: (context, itemBuilder) =>
                      ChatAnimatedList(
                        itemBuilder: itemBuilder,
                        reversed: true,
                        bottomPadding: 16,
                        scrollToBottomAppearanceThreshold: 200,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        insertAnimationDuration: const Duration(
                          milliseconds: 350,
                        ),
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

                        final showDateHeader = _shouldShowDateHeader(
                          message: message,
                          index: index,
                          messages: chatController.messages,
                        );

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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showDateHeader)
                                    _ChatDateHeader(date: message.createdAt!),
                                  VisibilityDetector(
                                    key: Key('msg-visibility-${message.id}'),
                                    onVisibilityChanged: (info) {
                                      if (info.visibleFraction > 0.1 &&
                                          !isSentByMe) {
                                        final repo = AppScope.of(
                                          context,
                                        ).repository;
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
                                ],
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
                    (
                      _,
                      msg, {
                      required int index,
                      required TapUpDetails details,
                    }) {
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

bool _shouldShowDateHeader({
  required Message message,
  required int index,
  required List<Message> messages,
}) {
  final messageDate = message.createdAt;
  if (messageDate == null) return false;
  if (index <= 0 || index >= messages.length) return true;

  final previousDate = messages[index - 1].createdAt;
  return previousDate == null || !_isSameCalendarDay(previousDate, messageDate);
}

bool _isSameCalendarDay(DateTime first, DateTime second) {
  final firstLocal = first.toLocal();
  final secondLocal = second.toLocal();
  return firstLocal.year == secondLocal.year &&
      firstLocal.month == secondLocal.month &&
      firstLocal.day == secondLocal.day;
}

class _ChatDateHeader extends StatelessWidget {
  const _ChatDateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final localDate = date.toLocal();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dateStart = DateTime(localDate.year, localDate.month, localDate.day);
    final daysAgo = todayStart.difference(dateStart).inDays;
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final label = switch (daysAgo) {
      0 => localizations.today,
      1 => localizations.yesterday,
      _ => DateFormat(
        localDate.year == today.year ? 'd MMMM' : 'd MMMM yyyy',
        locale,
      ).format(localDate),
    };

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.88),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.7),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
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
  State<_TypingIndicatorBuilder> createState() =>
      _TypingIndicatorBuilderState();
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
                                  ? AppLocalizations.of(context)!.printing
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
  const _AuroraBackground({
    required this.bgColor,
    required this.dotColor,
    required this.performanceMode,
  });
  final Color bgColor;
  final Color dotColor;
  final bool performanceMode;

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (!widget.performanceMode) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 20),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.performanceMode != widget.performanceMode) {
      if (widget.performanceMode) {
        _ctrl?.dispose();
        _ctrl = null;
      } else {
        _ctrl = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 20),
        )..repeat();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.performanceMode) {
      return CustomPaint(
        painter: _DotGridPainter(
          bgColor: widget.bgColor,
          dotColor: widget.dotColor,
          animationValue: 0.0,
          performanceMode: true,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl!,
      builder: (context, child) {
        return CustomPaint(
          painter: _DotGridPainter(
            bgColor: widget.bgColor,
            dotColor: widget.dotColor,
            animationValue: _ctrl!.value,
            performanceMode: false,
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
    required this.performanceMode,
  });
  final Color bgColor;
  final Color dotColor;
  final double animationValue;
  final bool performanceMode;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Solid background fill
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    if (!performanceMode) {
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
                      (0.7 +
                          0.2 * math.cos(animationValue * 2 * math.pi + 1.2)),
                  size.height *
                      (0.6 +
                          0.2 * math.sin(animationValue * 2 * math.pi + 1.2)),
                ),
                radius: size.width * 0.8,
              ),
            );
      canvas.drawRect(Offset.zero & size, glow2);
    }

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
      old.animationValue != animationValue ||
      old.performanceMode != performanceMode;
}
