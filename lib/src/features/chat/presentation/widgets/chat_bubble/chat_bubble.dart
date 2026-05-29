import 'package:school_world/l10n/app_localizations.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:school_world/src/theme.dart';

class SeenStatus extends StatelessWidget {
  const SeenStatus({
    super.key,
    required this.metadata,
    required this.myUid,
    this.mini = false,
    this.status,
  });
  final Map<String, dynamic>? metadata;
  final String myUid;
  final bool mini;
  final String? status;

  @override
  Widget build(BuildContext context) {
    if (status == 'sending') {
      return Icon(
        Icons.access_time_rounded,
        size: mini ? 12 : 13,
        color: mini ? Colors.white.withOpacity(0.5) : SchoolColors.muted,
      );
    }
    if (status == 'error') {
      return Icon(
        Icons.error_outline_rounded,
        size: mini ? 12 : 13,
        color: Colors.red,
      );
    }
    final seenBy = List<String>.from(metadata?['seenBy'] ?? []);
    final isSeen = seenBy.isNotEmpty;
    return Icon(
      isSeen ? Icons.done_all_rounded : Icons.done_rounded,
      size: mini ? 12 : 13,
      color: isSeen
          ? (mini ? Colors.white.withOpacity(0.9) : SchoolColors.primary)
          : (mini ? Colors.white.withOpacity(0.5) : SchoolColors.muted),
    );
  }
}

class ReplyContext extends StatelessWidget {
  const ReplyContext({
    super.key,
    required this.text,
    required this.isMe,
    this.onTap,
    this.isDeleted = false,
  });
  final String text;
  final bool isMe;
  final VoidCallback? onTap;
  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Colors for deleted reply context ──
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isDeleted) {
      if (isMe) {
        bgColor = Colors.white.withOpacity(0.25);
        borderColor = Colors.white.withOpacity(0.75);
        textColor = Colors.white.withOpacity(0.85);
      } else {
        bgColor = isDark
            ? SchoolColors.deletedBubbleDark
            : SchoolColors.deletedBubble;
        borderColor = isDark
            ? SchoolColors.deletedBubbleBorderDark
            : SchoolColors.deletedBubbleBorder;
        textColor = isDark
            ? SchoolColors.deletedBubbleTextDark
            : SchoolColors.deletedBubbleText;
      }
    } else {
      if (isMe) {
        bgColor = Colors.black.withOpacity(0.18);
        borderColor = Colors.white.withOpacity(0.95);
        textColor = Colors.white;
      } else {
        bgColor = const Color(0xFF2563EB).withOpacity(0.18);
        borderColor = const Color(0xFF2563EB);
        textColor = const Color(0xFF1E3A8A); // Deep navy blue
      }
    }

    return GestureDetector(
      onTap: isDeleted ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: borderColor, width: 3.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDeleted) ...[
              Icon(Icons.block_rounded, size: 12, color: textColor),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                isDeleted ? AppLocalizations.of(context)!.postDeleted : text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  decoration: isDeleted ? TextDecoration.lineThrough : null,
                  decorationColor: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReplyPreview extends StatelessWidget {
  const ReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
  });
  final Message message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final content = message is TextMessage
        ? (message as TextMessage).text
        : AppLocalizations.of(context)!.attachment;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.replyToMessage,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class EditPreview extends StatelessWidget {
  const EditPreview({super.key, required this.message, required this.onCancel});
  final Message message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final content = message is TextMessage ? (message as TextMessage).text : '';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SchoolColors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: SchoolColors.orange, width: 3.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_note_rounded,
            size: 20,
            color: SchoolColors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.editing,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: SchoolColors.orange,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class ReactionPill extends StatefulWidget {
  const ReactionPill({
    super.key,
    required this.emoji,
    required this.count,
    required this.mine,
    required this.users,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool mine;
  final List<String> users;
  final VoidCallback onTap;

  @override
  State<ReactionPill> createState() => _ReactionPillState();
}

class _ReactionPillState extends State<ReactionPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tooltip = widget.users.isEmpty
        ? widget.emoji
        : '${widget.emoji} · ${widget.count} reaction${widget.count == 1 ? '' : 's'}';

    return ScaleTransition(
      scale: _scale,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () {
            widget.onTap();
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.mine
                  ? const Color(0xFF2563EB).withOpacity(0.13)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.mine
                    ? const Color(0xFF2563EB).withOpacity(0.5)
                    : theme.colorScheme.outlineVariant,
                width: widget.mine ? 1.5 : 1.0,
              ),
              boxShadow: widget.mine
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.emoji,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamilyFallback: [
                      'Apple Color Emoji',
                      'Segoe UI Emoji',
                      'Noto Color Emoji',
                      'Android Emoji',
                      'EmojiOne',
                    ],
                  ),
                ),
                if (widget.count > 0) ...[
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      '${widget.count}',
                      key: ValueKey('count-${widget.count}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: widget.mine
                            ? const Color(0xFF2563EB)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReactionsRow extends StatelessWidget {
  const ReactionsRow({
    super.key,
    required this.reactions,
    required this.myUid,
    required this.onTap,
    required this.isSentByMe,
  });

  final Map<String, List<String>> reactions;
  final String myUid;
  final ValueChanged<String> onTap;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final entries = reactions.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Wrap(
          alignment: isSentByMe ? WrapAlignment.end : WrapAlignment.start,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in entries)
              ReactionPill(
                key: ValueKey('reaction-${entry.key}'),
                emoji: entry.key,
                count: entry.value.length,
                mine: entry.value.contains(myUid),
                users: entry.value,
                onTap: () => onTap(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.color, this.size = 5});
  final Color? color;
  final double size;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? SchoolColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Staggered bounce logic
            final double begin = index * 0.2;
            final double end = begin + 0.6;
            double value = 0.0;

            if (_controller.value >= begin && _controller.value <= end) {
              final relative = (_controller.value - begin) / 0.6;
              value = sin(relative * pi); // 0 -> 1 -> 0
            }

            return Container(
              width: widget.size,
              height: widget.size,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              transform: Matrix4.translationValues(0, -value * 4, 0),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.3 + (value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
