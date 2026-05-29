import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:sw_design_system/design_system.dart';

import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.classId,
    required this.currentUserId,
    super.key,
  });

  final String classId;
  final String currentUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(classMessagesProvider(widget.classId));
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.unknownKey)),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (items) => ListView.separated(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final message = items[index];
                  return SwChatBubble(
                    content: message.content,
                    isMine: message.senderId == widget.currentUserId,
                  );
                },
              ),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 2000,
                      decoration: const InputDecoration(hintText: 'Сообщение'),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () async {
                      final text = _controller.text;
                      _controller.clear();
                      await ref.read(sendMessageUseCaseProvider)(
                        classId: widget.classId,
                        senderId: widget.currentUserId,
                        content: text,
                      );
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
