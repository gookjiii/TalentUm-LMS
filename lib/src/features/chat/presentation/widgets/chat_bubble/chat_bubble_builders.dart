import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/main.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_bubble/chat_bubble.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:school_world/src/widgets/image_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/features/chat/data/reactions_notifier.dart';
import 'package:school_world/src/features/chat/presentation/widgets/chat_bubble/inline_video_player.dart';
import 'package:school_world/src/utils/string_extensions.dart';

class ChatBubbleBuilders {
  final FirebaseChatController? chatController;
  final String myUid;
  final Future<User?> Function(String) resolveUser;
  final void Function(Message, {Offset? position}) showMessageOptions;
  final void Function(Message) onReply;
  final void Function(String) openAttachment;
  final void Function(ImageMessage)? onImageTap;
  final String? roomId;
  final Color classColor;

  ChatBubbleBuilders({
    required this.chatController,
    required this.myUid,
    required this.resolveUser,
    required this.showMessageOptions,
    required this.onReply,
    required this.openAttachment,
    this.onImageTap,
    required this.roomId,
    this.classColor = SchoolColors.primary,
  });

  Widget buildTextMessage(
    BuildContext context,
    TextMessage message,
    int index, {
    required bool isSentByMe,
    dynamic groupStatus,
  }) {
    final query = chatController?.searchQuery ?? '';
    final isCurrentMatch =
        chatController?.searchResults.isNotEmpty == true &&
        chatController?.searchIndex != -1 &&
        chatController?.searchResults[chatController!.searchIndex] ==
            message.id;

    final isDeleted = message.metadata?['isDeleted'] == true;

    if (isDeleted) {
      return _buildDeletedBubble(
        context: context,
        message: message,
        isSentByMe: isSentByMe,
      );
    }

    return buildBubbleShell(
      context: context,
      messageId: message.id,
      authorId: message.authorId,
      createdAt: _toDate(message.createdAt),
      metadata: message.metadata,
      isSentByMe: isSentByMe,
      onLongPress: (details) =>
          showMessageOptions(message, position: details.globalPosition),
      onReply: () => onReply(message),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: isSentByMe ? null : SchoolColors.chatBubbleOther,
          border: !isSentByMe
              ? Border.all(color: SchoolColors.chatBubbleOtherBorder, width: 1)
              : null,
          gradient: isSentByMe
              ? const LinearGradient(
                  colors: [
                    SchoolColors.chatBubbleStart,
                    SchoolColors.chatBubbleEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: isSentByMe
                ? const Radius.circular(22)
                : const Radius.circular(6),
            bottomRight: isSentByMe
                ? const Radius.circular(6)
                : const Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: isSentByMe
                  ? const Color(0xFF2563EB).withOpacity(0.15)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildHighlightedText(
              context,
              message.text,
              query,
              isSentByMe,
              isCurrentMatch: isCurrentMatch,
              isDeleted: false,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.metadata?['isEdited'] == true)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      AppLocalizations.of(context)!.changed,
                      style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: isSentByMe
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                Text(
                  _formatTime(_toDate(message.createdAt)),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSentByMe
                        ? Colors.white.withOpacity(0.75)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSentByMe) ...[
                  const SizedBox(width: 4),
                  SeenStatus(
                    metadata: message.metadata,
                    myUid: myUid,
                    mini: true,
                    status: message.status?.name,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedBubble({
    required BuildContext context,
    required Message message,
    required bool isSentByMe,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return buildBubbleShell(
      context: context,
      messageId: message.id,
      authorId: message.authorId,
      createdAt: _toDate(message.createdAt),
      metadata: message.metadata,
      isSentByMe: isSentByMe,
      onLongPress: null,
      onReply: null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: isDark
              ? SchoolColors.deletedBubbleDark
              : SchoolColors.deletedBubble,
          border: Border.all(
            color: isDark
                ? SchoolColors.deletedBubbleBorderDark
                : SchoolColors.deletedBubbleBorder,
            width: 1.5,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: isSentByMe
                ? const Radius.circular(22)
                : const Radius.circular(6),
            bottomRight: isSentByMe
                ? const Radius.circular(6)
                : const Radius.circular(22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildHighlightedText(
              context,
              AppLocalizations.of(context)!.postDeleted,
              '',
              isSentByMe,
              isCurrentMatch: false,
              isDeleted: true,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_toDate(message.createdAt)),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSentByMe
                        ? Colors.white.withOpacity(0.75)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSentByMe) ...[
                  const SizedBox(width: 4),
                  SeenStatus(
                    metadata: message.metadata,
                    myUid: myUid,
                    mini: true,
                    status: message.status?.name,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImageMessage(
    BuildContext context,
    ImageMessage message,
    int index, {
    required bool isSentByMe,
    dynamic groupStatus,
  }) {
    if (message.metadata?['isDeleted'] == true) {
      return _buildDeletedBubble(
        context: context,
        message: message,
        isSentByMe: isSentByMe,
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageWidth = screenWidth < 520 ? screenWidth * .62 : 260.0;
    final msgText = message.metadata?['text'] as String?;

    return buildBubbleShell(
      context: context,
      messageId: message.id,
      authorId: message.authorId,
      createdAt: _toDate(message.createdAt),
      metadata: message.metadata,
      isSentByMe: isSentByMe,
      onLongPress: (details) =>
          showMessageOptions(message, position: details.globalPosition),
      onReply: () => onReply(message),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (onImageTap != null) {
                    onImageTap!(message);
                  } else {
                    showDialog(
                      context: context,
                      builder: (_) => ImageViewer(
                        imageUrl: message.source.toDirectImageUrl,
                      ),
                    );
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(msgText == null ? 18 : 6),
                      bottomRight: Radius.circular(msgText == null ? 18 : 6),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: message.source.toDirectImageUrl,
                      width: imageWidth,
                      fit: BoxFit.cover,
                      memCacheWidth: (imageWidth * 2.5).round(),
                      placeholder: (context, url) => Container(
                        width: imageWidth,
                        height: 120,
                        color: SchoolColors.surface,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: imageWidth,
                        height: 120,
                        color: SchoolColors.surface,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: SchoolColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => openAttachment(message.source),
                  icon: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.45),
                  ),
                ),
              ),
              if (msgText == null)
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_toDate(message.createdAt)),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 4),
                        SeenStatus(
                          metadata: message.metadata,
                          myUid: myUid,
                          mini: true,
                          status: message.status?.name,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          if (msgText != null)
            Container(
              width: imageWidth,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              decoration: BoxDecoration(
                color: isSentByMe
                    ? null
                    : Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.5),
                gradient: isSentByMe
                    ? const LinearGradient(
                        colors: [
                          SchoolColors.chatBubbleStart,
                          SchoolColors.chatBubbleEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  buildHighlightedText(
                    context,
                    msgText,
                    chatController?.searchQuery ?? '',
                    isSentByMe,
                    isCurrentMatch:
                        chatController?.searchResults.isNotEmpty == true &&
                        chatController?.searchIndex != -1 &&
                        chatController?.searchResults[chatController!
                                .searchIndex] ==
                            message.id,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_toDate(message.createdAt)),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSentByMe
                              ? Colors.white.withOpacity(0.7)
                              : SchoolColors.muted.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 4),
                        SeenStatus(
                          metadata: message.metadata,
                          myUid: myUid,
                          mini: true,
                          status: message.status?.name,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildFileMessage(
    BuildContext context,
    FileMessage message,
    int index, {
    required bool isSentByMe,
    dynamic groupStatus,
  }) {
    if (message.metadata?['isDeleted'] == true) {
      return _buildDeletedBubble(
        context: context,
        message: message,
        isSentByMe: isSentByMe,
      );
    }

    final msgText = message.metadata?['text'] as String?;

    // --- Audio / Voice message ---
    final isAudio =
        message.metadata?['type'] == 'audio' ||
        message.mimeType?.startsWith('audio/') == true ||
        RegExp(
          r'\.(m4a|mp3|ogg|aac|wav|opus|webm)$',
          caseSensitive: false,
        ).hasMatch(message.name);

    if (isAudio) {
      final durationMs = message.metadata?['durationMs'] as int? ?? 0;
      final audioDuration = Duration(milliseconds: durationMs);
      return buildBubbleShell(
        context: context,
        messageId: message.id,
        authorId: message.authorId,
        createdAt: _toDate(message.createdAt),
        metadata: message.metadata,
        isSentByMe: isSentByMe,
        onLongPress: (details) =>
            showMessageOptions(message, position: details.globalPosition),
        onReply: () => onReply(message),
        child: Container(
          decoration: BoxDecoration(
            color: isSentByMe ? null : SchoolColors.chatBubbleOther,
            gradient: isSentByMe
                ? const LinearGradient(
                    colors: [
                      SchoolColors.chatBubbleStart,
                      SchoolColors.chatBubbleEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: isSentByMe
                ? null
                : Border.all(
                    color: SchoolColors.chatBubbleOtherBorder,
                    width: 1,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: isSentByMe
                  ? const Radius.circular(22)
                  : const Radius.circular(6),
              bottomRight: isSentByMe
                  ? const Radius.circular(6)
                  : const Radius.circular(22),
            ),
          ),
          child: _AudioBubble(
            url: message.source,
            duration: audioDuration,
            isSentByMe: isSentByMe,
            createdAt: _toDate(message.createdAt),
          ),
        ),
      );
    }

    final isVideo =
        message.mimeType?.startsWith('video/') == true ||
        RegExp(
          r'\.(mp4|mov|webm|mkv)$',
          caseSensitive: false,
        ).hasMatch(message.name);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final videoWidth = screenWidth < 520 ? screenWidth * .62 : 260.0;

    return buildBubbleShell(
      context: context,
      messageId: message.id,
      authorId: message.authorId,
      createdAt: _toDate(message.createdAt),
      metadata: message.metadata,
      isSentByMe: isSentByMe,
      onLongPress: (details) =>
          showMessageOptions(message, position: details.globalPosition),
      onReply: () => onReply(message),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVideo)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
              child: SizedBox(
                width: videoWidth,
                child: InlineVideoPlayer(videoUrl: message.source),
              ),
            )
          else
            _FileAttachmentCard(
              name: message.name,
              size: message.size ?? 0,
              url: message.source,
              isSentByMe: isSentByMe,
              createdAt: _toDate(message.createdAt) ?? DateTime.now(),
              metadata: message.metadata,
              myUid: myUid,
              openAttachment: openAttachment,
              msgText: msgText,
              searchQuery: chatController?.searchQuery ?? '',
              isCurrentMatch:
                  chatController?.searchResults.isNotEmpty == true &&
                  chatController?.searchIndex != -1 &&
                  chatController?.searchResults[chatController!.searchIndex] ==
                      message.id,
              buildHighlightedText: buildHighlightedText,
            ),
        ],
      ),
    );
  }

  Widget buildBubbleShell({
    required BuildContext context,
    required String messageId,
    required String authorId,
    required DateTime? createdAt,
    required Map<String, dynamic>? metadata,
    required bool isSentByMe,
    required Widget child,
    void Function(LongPressStartDetails)? onLongPress,
    VoidCallback? onReply,
  }) {
    final replyText = metadata?['replyToText'] as String?;
    final isDeleted = metadata?['isDeleted'] == true;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth < 700 ? screenWidth * .72 : 520.0;

    final performanceMode = AppScope.of(context).appState.performanceMode;

    final shellContent = _SwipeToReplyWrapper(
      isDeleted: isDeleted,
      isSentByMe: isSentByMe,
      classColor: classColor,
      onLongPress: onLongPress,
      onReply: onReply,
      builder: (context, isHovered, dragOffset) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isSentByMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isSentByMe) ...[
                Padding(
                  padding: EdgeInsets.only(top: (replyText != null) ? 48 : 24),
                  child: SchoolAvatar(
                    name: authorId,
                    userId: authorId,
                    radius: 14,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isSentByMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isSentByMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              label: AppLocalizations.of(context)!.sender,
                              child: _SenderName(
                                authorId: authorId,
                                resolveUser: resolveUser,
                                classColor: classColor,
                              ),
                            ),
                            TeacherTag(userId: authorId),
                          ],
                        ),
                      ),
                    if (replyText != null)
                      Semantics(
                        label: AppLocalizations.of(context)!.replyToAMessage,
                        child: ReplyContext(
                          text: replyText,
                          isMe: isSentByMe,
                          isDeleted: metadata?['isReplyDeleted'] == true,
                          onTap: (metadata?['replyToId'] as String?) == null
                              ? null
                              : () => chatController?.scrollToMessage(
                                  metadata!['replyToId'] as String,
                                ),
                        ),
                      ),
                    Semantics(
                      container: true,
                      label: AppLocalizations.of(context)!.messageText,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (performanceMode)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft: Radius.circular(
                                            isSentByMe ? 18 : 2,
                                          ),
                                          bottomRight: Radius.circular(
                                            isSentByMe ? 2 : 18,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSentByMe
                                                ? const Color(
                                                    0xFF2563EB,
                                                  ).withOpacity(0.18)
                                                : Colors.black.withOpacity(
                                                    0.04,
                                                  ),
                                            blurRadius: isSentByMe ? 10 : 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: math.max(
                                            40.0,
                                            math.min(
                                              maxBubbleWidth,
                                              constraints.maxWidth,
                                            ),
                                          ),
                                          minWidth: math.min(
                                            40.0,
                                            constraints.maxWidth,
                                          ),
                                        ),
                                        child: child,
                                      ),
                                    )
                                  else ...[
                                    AnimatedScale(
                                      scale: isHovered && !isDeleted
                                          ? 1.015
                                          : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(18),
                                            topRight: const Radius.circular(18),
                                            bottomLeft: Radius.circular(
                                              isSentByMe ? 18 : 2,
                                            ),
                                            bottomRight: Radius.circular(
                                              isSentByMe ? 2 : 18,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSentByMe
                                                  ? const Color(
                                                      0xFF2563EB,
                                                    ).withOpacity(
                                                      isHovered ? 0.30 : 0.18,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      isHovered ? 0.08 : 0.04,
                                                    ),
                                              blurRadius: isHovered
                                                  ? (isSentByMe ? 18 : 10)
                                                  : (isSentByMe ? 10 : 5),
                                              offset: Offset(
                                                0,
                                                isHovered ? 4 : 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: math.max(
                                              40.0,
                                              math.min(
                                                maxBubbleWidth,
                                                constraints.maxWidth,
                                              ),
                                            ),
                                            minWidth: math.min(
                                              40.0,
                                              constraints.maxWidth,
                                            ),
                                          ),
                                          child: child,
                                        ),
                                      ),
                                    ),
                                    if (isSentByMe && isHovered && !isDeleted)
                                      Positioned(
                                        left: -32,
                                        top: 0,
                                        bottom: 0,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.reply_rounded,
                                            size: 18,
                                            color: SchoolColors.muted,
                                          ),
                                          onPressed: onReply,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    if (!isSentByMe && isHovered && !isDeleted)
                                      Positioned(
                                        right: -32,
                                        top: 0,
                                        bottom: 0,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.reply_rounded,
                                            size: 18,
                                            color: SchoolColors.muted,
                                          ),
                                          onPressed: onReply,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (!isDeleted)
                      _ReactionsArea(
                        roomId: roomId,
                        messageId: messageId,
                        myUid: myUid,
                        metadata: metadata,
                        isSentByMe: isSentByMe,
                      ),
                  ],
                ),
              ),
              if (isSentByMe) const SizedBox(width: 10),
            ],
          ),
        );
      },
    );

    if (performanceMode) {
      return shellContent;
    } else {
      return _BubbleEntrance(child: shellContent);
    }
  }

  Widget buildHighlightedText(
    BuildContext context,
    String text,
    String query,
    bool isSentByMe, {
    bool isCurrentMatch = false,
    bool isDeleted = false,
  }) {
    if (isDeleted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final deletedColor = isDark
          ? SchoolColors.deletedBubbleTextDark
          : SchoolColors.deletedBubbleText;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, size: 16, color: deletedColor),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!.postDeleted,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: deletedColor,
              height: 1.4,
              letterSpacing: 0.1,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.lineThrough,
              decorationColor: deletedColor.withOpacity(0.5),
            ),
          ),
        ],
      );
    }
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      color: isSentByMe ? Colors.white : const Color(0xFF0F172A),
      height: 1.4,
      letterSpacing: 0.1,
      fontStyle: FontStyle.normal,
    );

    final spans = _parseRichText(
      context,
      text,
      query,
      isSentByMe,
      isCurrentMatch,
      baseStyle!,
    );

    return Text.rich(TextSpan(children: spans, style: baseStyle));
  }

  List<InlineSpan> _parseRichText(
    BuildContext context,
    String text,
    String query,
    bool isSentByMe,
    bool isCurrentMatch,
    TextStyle baseStyle,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<InlineSpan> spans = [];

    void addHighlightedTextSegment(String segment, TextStyle style) {
      if (segment.isEmpty) return;
      if (query.isEmpty ||
          !segment.toLowerCase().contains(query.toLowerCase())) {
        spans.add(TextSpan(text: segment, style: style));
        return;
      }

      final lowerSegment = segment.toLowerCase();
      final lowerQuery = query.toLowerCase();
      int start = 0;
      int index = lowerSegment.indexOf(lowerQuery);

      while (index != -1) {
        if (index > start) {
          spans.add(
            TextSpan(text: segment.substring(start, index), style: style),
          );
        }
        spans.add(
          TextSpan(
            text: segment.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: isCurrentMatch
                  ? Colors.orange.withOpacity(0.8)
                  : Colors.yellow.withOpacity(0.5),
              color: isCurrentMatch ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        start = index + query.length;
        index = lowerSegment.indexOf(lowerQuery, start);
      }
      if (start < segment.length) {
        spans.add(TextSpan(text: segment.substring(start), style: style));
      }
    }

    void addMarkdownSegment(String segment, TextStyle style) {
      if (segment.isEmpty) return;

      final mdRegExp = RegExp(r'(`[^`]+`|\*[^*]+\*|_[^_]+_|~[^~]+~)');
      final matches = mdRegExp.allMatches(segment);

      if (matches.isEmpty) {
        addHighlightedTextSegment(segment, style);
        return;
      }

      int lastMdEnd = 0;
      for (final match in matches) {
        if (match.start > lastMdEnd) {
          addHighlightedTextSegment(
            segment.substring(lastMdEnd, match.start),
            style,
          );
        }

        final matchedStr = match.group(0)!;
        final char = matchedStr[0];
        final innerContent = matchedStr.substring(1, matchedStr.length - 1);

        if (char == '`') {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSentByMe
                      ? Colors.black.withOpacity(0.22)
                      : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5FD)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSentByMe
                        ? Colors.white.withOpacity(0.18)
                        : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFDBEAFE)),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  innerContent,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSentByMe
                        ? Colors.white
                        : (isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF1D4ED8)),
                  ),
                ),
              ),
            ),
          );
        } else {
          TextStyle mdStyle = style;
          if (char == '*') {
            mdStyle = style.copyWith(fontWeight: FontWeight.w900);
          } else if (char == '_') {
            mdStyle = style.copyWith(fontStyle: FontStyle.italic);
          } else if (char == '~') {
            mdStyle = style.copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: style.color?.withOpacity(0.6),
              decorationThickness: 1.5,
            );
          }
          addHighlightedTextSegment(innerContent, mdStyle);
        }

        lastMdEnd = match.end;
      }

      if (lastMdEnd < segment.length) {
        addHighlightedTextSegment(segment.substring(lastMdEnd), style);
      }
    }

    // Top-level parsing: URLs first!
    final urlRegExp = RegExp(r'(https?://[^\s]+)');
    final matches = urlRegExp.allMatches(text);

    int lastUrlEnd = 0;
    for (final match in matches) {
      if (match.start > lastUrlEnd) {
        addMarkdownSegment(text.substring(lastUrlEnd, match.start), baseStyle);
      }

      final urlStr = match.group(0)!;
      spans.add(
        TextSpan(
          text: urlStr,
          style: baseStyle.copyWith(
            color: isSentByMe
                ? Colors.white.withOpacity(0.95)
                : SchoolColors.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(urlStr);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                try {
                  await launchUrl(uri);
                } catch (e2) {
                  debugPrint('Could not launch $urlStr: $e2');
                }
              }
            },
        ),
      );
      lastUrlEnd = match.end;
    }

    if (lastUrlEnd < text.length) {
      addMarkdownSegment(text.substring(lastUrlEnd), baseStyle);
    }

    return spans;
  }

  Widget buildAudioMessage(
    BuildContext context,
    FileMessage message,
    int index, {
    required bool isSentByMe,
    dynamic groupStatus,
  }) {
    if (message.metadata?['isDeleted'] == true) {
      return _buildDeletedBubble(
        context: context,
        message: message,
        isSentByMe: isSentByMe,
      );
    }
    final durationMs = message.metadata?['durationMs'] as int? ?? 0;
    return buildBubbleShell(
      context: context,
      messageId: message.id,
      authorId: message.authorId,
      createdAt: _toDate(message.createdAt),
      metadata: message.metadata,
      isSentByMe: isSentByMe,
      onLongPress: (details) =>
          showMessageOptions(message, position: details.globalPosition),
      onReply: () => onReply(message),
      child: Container(
        decoration: BoxDecoration(
          color: isSentByMe ? null : SchoolColors.chatBubbleOther,
          gradient: isSentByMe
              ? const LinearGradient(
                  colors: [
                    SchoolColors.chatBubbleStart,
                    SchoolColors.chatBubbleEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: isSentByMe
              ? null
              : Border.all(color: SchoolColors.chatBubbleOtherBorder, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isSentByMe
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isSentByMe
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
        ),
        child: _AudioBubble(
          url: message.source,
          duration: Duration(milliseconds: durationMs),
          isSentByMe: isSentByMe,
          createdAt: _toDate(message.createdAt),
        ),
      ),
    );
  }

  DateTime? _toDate(dynamic val) {
    if (val is DateTime) return val;
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }
}

class _ReactionsArea extends ConsumerWidget {
  const _ReactionsArea({
    required this.roomId,
    required this.messageId,
    required this.myUid,
    required this.metadata,
    required this.isSentByMe,
  });
  final String? roomId;
  final String messageId;
  final String myUid;
  final Map<String, dynamic>? metadata;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (roomId == null) return const SizedBox.shrink();
    final reactions = ref.watch(
      reactionsProvider(
        roomId!,
      ).select((state) => state[messageId] ?? const <String, List<String>>{}),
    );

    ReactionsRow? row;
    if (reactions.isEmpty) {
      final fallback = metadata?['reactions'];
      if (fallback is Map && fallback.isNotEmpty) {
        final hydrated = <String, List<String>>{
          for (final entry in fallback.entries)
            if (List<String>.from(entry.value as List? ?? const []).isNotEmpty)
              entry.key.toString(): List<String>.from(
                entry.value as List? ?? const [],
              ),
        };
        if (hydrated.isNotEmpty)
          row = ReactionsRow(
            reactions: hydrated,
            myUid: myUid,
            isSentByMe: isSentByMe,
            onTap: (emoji) => ref
                .read(reactionsProvider(roomId!).notifier)
                .toggle(messageId: messageId, emoji: emoji, userId: myUid),
          );
      }
    } else {
      row = ReactionsRow(
        reactions: reactions,
        myUid: myUid,
        isSentByMe: isSentByMe,
        onTap: (emoji) => ref
            .read(reactionsProvider(roomId!).notifier)
            .toggle(messageId: messageId, emoji: emoji, userId: myUid),
      );
    }

    final isPerformance = AppScope.of(context).appState.performanceMode;
    if (isPerformance) {
      return row != null
          ? KeyedSubtree(key: const ValueKey('has'), child: row)
          : const SizedBox.shrink();
    }

    // SizeTransition inside AnimatedSwitcher caused the pill to render at the
    // left edge of the screen (Stack alignment mis-position). FadeTransition
    // only is safe here — the row expands naturally when it appears.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: row != null
          ? KeyedSubtree(key: const ValueKey('has'), child: row)
          : const SizedBox.shrink(),
    );
  }
}

class _BubbleEntrance extends StatefulWidget {
  const _BubbleEntrance({required this.child});
  final Widget child;
  @override
  State<_BubbleEntrance> createState() => _BubbleEntranceState();
}

class _BubbleEntranceState extends State<_BubbleEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _offset = Tween<double>(
      begin: 10.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
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
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _offset.value),
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
      child: widget.child,
    );
  }
}

class _AudioBubble extends StatefulWidget {
  const _AudioBubble({
    required this.url,
    required this.duration,
    required this.isSentByMe,
    required this.createdAt,
  });

  final String url;
  final Duration duration;
  final bool isSentByMe;
  final DateTime? createdAt;

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  static const List<double> _barHeights = [
    12.0,
    24.0,
    16.0,
    8.0,
    30.0,
    42.0,
    22.0,
    14.0,
    28.0,
    36.0,
    18.0,
    10.0,
    32.0,
    40.0,
    26.0,
    12.0,
    20.0,
    28.0,
    14.0,
    6.0,
  ];

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.duration;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() => _playerState = s);
        if (s == PlayerState.playing) {
          _pulseCtrl.repeat(reverse: true);
        } else {
          _pulseCtrl.stop();
        }
      }
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _totalDuration = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else if (_playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        String playUrl = widget.url;
        // Legacy Google Drive audio URLs → direct download proxy
        if (playUrl.contains('drive.google.com') || playUrl.contains('docs.google.com')) {
          final uri = Uri.tryParse(playUrl);
          final fileId = uri?.queryParameters['id'] ??
              RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)').firstMatch(playUrl)?.group(1);
          if (fileId != null) {
            playUrl = 'https://docs.google.com/uc?export=download&id=$fileId';
          }
        }

        // For Cloudinary audio/video URLs, transcode on-the-fly to MP3 format
        if (playUrl.contains('cloudinary.com') && playUrl.contains('/upload/')) {
          playUrl = playUrl.replaceFirst(
            RegExp(r'/upload/([^/]+/)?'),
            '/upload/f_mp3,q_auto/',
          );
          if (playUrl.contains('.')) {
            playUrl = playUrl.replaceFirst(RegExp(r'\.[a-zA-Z0-9]+(?=\?|$)'), '.mp3');
          }
        }

        // On Web, if url is Firebase Storage or HTTP audio url that might lack CORS headers,
        // use http.get to load bytes into memory and play via BytesSource for zero CORS restrictions
        if (kIsWeb && !playUrl.contains('cloudinary.com')) {
          try {
            final response = await http.get(Uri.parse(playUrl));
            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              debugPrint('[_AudioBubble] Playing via BytesSource (${response.bodyBytes.length} bytes)');
              await _player.play(BytesSource(response.bodyBytes));
              return;
            }
          } catch (e) {
            debugPrint('[_AudioBubble] BytesSource fetch error: $e');
          }
        }

        debugPrint('[_AudioBubble] Playing audio URL: $playUrl');
        await _player.play(UrlSource(playUrl));
      }
    } catch (e) {
      debugPrint('[_AudioBubble] Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot play audio: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleScrub(double localX, double totalWidth) {
    if (totalWidth <= 0 || _totalDuration.inMilliseconds <= 0) return;
    final pct = (localX / totalWidth).clamp(0.0, 1.0);
    final targetMs = (_totalDuration.inMilliseconds * pct).toInt();
    _player.seek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSentByMe ? Colors.white : SchoolColors.primary;
    final progress = _totalDuration.inMilliseconds > 0
        ? (_position.inMilliseconds / _totalDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _togglePlay,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(_playerState),
                    color: widget.isSentByMe
                        ? SchoolColors.primary
                        : Colors.white,
                    size: 20,
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: widget.isSentByMe
                      ? Colors.white
                      : SchoolColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  maximumSize: const Size(36, 36),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) =>
                          _handleScrub(details.localPosition.dx, width),
                      onHorizontalDragUpdate: (details) =>
                          _handleScrub(details.localPosition.dx, width),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_barHeights.length, (
                                index,
                              ) {
                                final barPct = index / _barHeights.length;
                                final isActive = progress >= barPct;
                                final pulse =
                                    _playerState == PlayerState.playing &&
                                    index ==
                                        (progress * _barHeights.length).floor();

                                double height = _barHeights[index];
                                if (pulse) {
                                  height += 8.0 * _pulseCtrl.value;
                                }

                                return Container(
                                  width:
                                      (width - (_barHeights.length * 2)) /
                                      _barHeights.length,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? color
                                        : color.withOpacity(0.24),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 46, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(
                    _playerState == PlayerState.playing
                        ? _position
                        : _totalDuration,
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatTimeBubble(widget.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTimeBubble(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

String _formatTime(DateTime? dt) => dt == null
    ? ''
    : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
String _formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = (math.log(bytes) / math.log(1024)).floor();
  return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

class _SwipeToReplyWrapper extends StatefulWidget {
  const _SwipeToReplyWrapper({
    required this.isDeleted,
    required this.isSentByMe,
    required this.classColor,
    this.onLongPress,
    this.onReply,
    required this.builder,
  });

  final bool isDeleted;
  final bool isSentByMe;
  final Color classColor;
  final void Function(LongPressStartDetails)? onLongPress;
  final VoidCallback? onReply;
  final Widget Function(BuildContext context, bool isHovered, double dragOffset)
  builder;

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper> {
  double _dragOffset = 0.0;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPerformance = AppScope.of(context).appState.performanceMode;
    if (isPerformance) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: widget.isDeleted ? null : widget.onLongPress,
        child: widget.builder(context, false, 0.0),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: widget.isDeleted ? null : widget.onLongPress,
        onHorizontalDragUpdate: widget.isDeleted
            ? null
            : (details) {
                setState(() {
                  final delta = details.primaryDelta ?? 0;
                  _dragOffset += delta * 0.45;
                  if (widget.isSentByMe) {
                    _dragOffset = _dragOffset.clamp(-80.0, 10.0);
                  } else {
                    _dragOffset = _dragOffset.clamp(-10.0, 80.0);
                  }
                });
              },
        onHorizontalDragEnd: widget.isDeleted
            ? null
            : (details) {
                if (_dragOffset.abs() >= 45) {
                  widget.onReply?.call();
                  HapticFeedback.lightImpact();
                }
                setState(() => _dragOffset = 0.0);
              },
        child: Opacity(
          opacity: widget.isDeleted ? 0.6 : 1.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (_dragOffset.abs() > 5 && !widget.isDeleted)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: widget.isSentByMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Transform.translate(
                        offset: Offset(widget.isSentByMe ? 60 : -60, 0),
                        child: Transform.scale(
                          scale: (_dragOffset.abs() / 50).clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.classColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.reply_rounded,
                              color: widget.classColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: Duration(milliseconds: _dragOffset == 0 ? 400 : 0),
                curve: Curves.elasticOut,
                transform: Matrix4.translationValues(_dragOffset, 0, 0),
                child: widget.builder(context, _isHovered, _dragOffset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SenderName extends StatefulWidget {
  const _SenderName({
    required this.authorId,
    required this.resolveUser,
    required this.classColor,
  });

  final String authorId;
  final Future<User?> Function(String) resolveUser;
  final Color classColor;

  static final Map<String, String> _senderNamesCache = {};

  @override
  State<_SenderName> createState() => _SenderNameState();
}

class _SenderNameState extends State<_SenderName> {
  String? _cachedName;

  @override
  void initState() {
    super.initState();
    _cachedName = _SenderName._senderNamesCache[widget.authorId];
    if (_cachedName == null) {
      _resolve();
    }
  }

  @override
  void didUpdateWidget(covariant _SenderName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorId != widget.authorId) {
      _cachedName = _SenderName._senderNamesCache[widget.authorId];
      if (_cachedName == null) {
        _resolve();
      }
    }
  }

  Future<void> _resolve() async {
    try {
      final user = await widget.resolveUser(widget.authorId);
      if (user != null && mounted) {
        final name = user.name ?? '';
        _SenderName._senderNamesCache[widget.authorId] = name;
        setState(() {
          _cachedName = name;
        });
      }
    } catch (_) {
      // Keep silent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _cachedName ?? '',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: widget.classColor,
      ),
    );
  }
}

class _FileAttachmentCard extends StatelessWidget {
  const _FileAttachmentCard({
    required this.name,
    required this.size,
    required this.url,
    required this.isSentByMe,
    required this.createdAt,
    required this.metadata,
    required this.myUid,
    required this.openAttachment,
    this.msgText,
    this.searchQuery = '',
    this.isCurrentMatch = false,
    required this.buildHighlightedText,
  });

  final String name;
  final int size;
  final String url;
  final bool isSentByMe;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String myUid;
  final void Function(String) openAttachment;
  final String? msgText;
  final String searchQuery;
  final bool isCurrentMatch;
  final Widget Function(
    BuildContext context,
    String text,
    String query,
    bool isSentByMe, {
    bool isCurrentMatch,
    bool isDeleted,
  }) buildHighlightedText;

  @override
  Widget build(BuildContext context) {
    final ext = name.split('.').last.toLowerCase();
    final fileConfig = _getFileTypeConfig(ext);

    return Container(
      constraints: const BoxConstraints(maxWidth: 320, minWidth: 240),
      decoration: BoxDecoration(
        color: isSentByMe ? null : SchoolColors.chatBubbleOther,
        gradient: isSentByMe
            ? const LinearGradient(
                colors: [
                  SchoolColors.chatBubbleStart,
                  SchoolColors.chatBubbleEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isSentByMe
              ? const Radius.circular(20)
              : const Radius.circular(6),
          bottomRight: isSentByMe
              ? const Radius.circular(6)
              : const Radius.circular(20),
        ),
        border: isSentByMe
            ? null
            : Border.all(color: SchoolColors.chatBubbleOtherBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isSentByMe
                ? const Color(0xFF2563EB).withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // File info row
          InkWell(
            onTap: () => openAttachment(url),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // File Badge Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: fileConfig.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: fileConfig.accentColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        fileConfig.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: isSentByMe
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${ext.toUpperCase()} · ${_formatBytes(size)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isSentByMe
                                ? Colors.white.withOpacity(0.75)
                                : SchoolColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action Download Button
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (isSentByMe ? Colors.white : fileConfig.accentColor)
                          .withOpacity(isSentByMe ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: isSentByMe ? Colors.white : fileConfig.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msgText != null && msgText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: buildHighlightedText(
                context,
                msgText!,
                searchQuery,
                isSentByMe,
                isCurrentMatch: isCurrentMatch,
              ),
            ),
          // Time & Status bottom right
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSentByMe
                        ? Colors.white.withOpacity(0.75)
                        : SchoolColors.muted.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSentByMe) ...[
                  const SizedBox(width: 4),
                  SeenStatus(
                    metadata: metadata,
                    myUid: myUid,
                    mini: true,
                    status: metadata?['status'] as String?,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _FileTypeConfig _getFileTypeConfig(String ext) {
    return switch (ext) {
      'pdf' => const _FileTypeConfig(
          icon: Icons.picture_as_pdf_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFFDC2626),
        ),
      'doc' || 'docx' => const _FileTypeConfig(
          icon: Icons.description_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF2563EB),
        ),
      'xls' || 'xlsx' => const _FileTypeConfig(
          icon: Icons.table_chart_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF059669),
        ),
      'ppt' || 'pptx' => const _FileTypeConfig(
          icon: Icons.slideshow_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFFD97706),
        ),
      'zip' || 'rar' || '7z' => const _FileTypeConfig(
          icon: Icons.folder_zip_rounded,
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Color(0xFF7C3AED),
        ),
      _ => const _FileTypeConfig(
          icon: Icons.insert_drive_file_rounded,
          gradient: LinearGradient(
            colors: [SchoolColors.chatBubbleStart, SchoolColors.chatBubbleEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: SchoolColors.primary,
        ),
    };
  }
}

class _FileTypeConfig {
  const _FileTypeConfig({
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
}
