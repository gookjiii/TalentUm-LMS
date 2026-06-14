import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';

class EliteCampusChat extends HookWidget {
  const EliteCampusChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              // Chat Explorer Sidebar
              SizedBox(
                width: 380,
                child: EliteNestedBezel(
                  padding: EdgeInsets.zero,
                  child: _ChatExplorer(),
                ),
              ),
              SizedBox(width: 12),
              // Main Chat View
              Expanded(
                child: EliteNestedBezel(
                  padding: EdgeInsets.zero,
                  child: _ChatView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatExplorer extends StatelessWidget {
  const _ChatExplorer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BackButton(color: Colors.white),
                  Text(
                    'Messages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: SchoolColors.darkBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: SchoolColors.darkMuted, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      'Search people or groups...',
                      style: AppTextStyle.bodyMd.copyWith(color: SchoolColors.darkMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: const [
              _ChannelItem(
                name: 'Advanced Calculus',
                initial: 'AC',
                lastMessage: 'Dr. Jenkins: Em đã nhận được file chưa?',
                unread: 3,
                isOnline: true,
                color: SchoolColors.primary,
                isActive: true,
              ),
              _ChannelItem(
                name: 'Project TalentUm',
                initial: 'PT',
                lastMessage: 'Sarah: Deadline is tonight!',
                unread: 0,
                isOnline: true,
                color: Colors.lightBlue,
              ),
              _ChannelItem(
                name: 'Student Council',
                initial: 'SC',
                lastMessage: 'Meeting at 5PM in Library.',
                unread: 12,
                isOnline: false,
                color: SchoolColors.orange,
              ),
              _ChannelItem(
                name: 'Deep Learning Group',
                initial: 'DL',
                lastMessage: 'Alex: Model is training...',
                unread: 0,
                isOnline: true,
                color: SchoolColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelItem extends HookWidget {
  const _ChannelItem({
    required this.name,
    required this.initial,
    required this.lastMessage,
    required this.unread,
    required this.isOnline,
    required this.color,
    this.isActive = false,
  });

  final String name;
  final String initial;
  final String lastMessage;
  final int unread;
  final bool isOnline;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive 
              ? SchoolColors.primary.withOpacity(0.1) 
              : (isHovered.value ? Colors.white.withOpacity(0.03) : Colors.transparent),
          border: Border.all(
            color: isActive ? SchoolColors.primary.withOpacity(0.2) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SchoolColors.darkBorder),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: SchoolColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: SchoolColors.darkBg, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: SchoolColors.success.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: SchoolColors.darkMuted,
                      fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: SchoolColors.primary,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: SchoolColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatView extends HookWidget {
  const _ChatView();

  @override
  Widget build(BuildContext context) {
    final messages = useState([
      { 'id': 1, 'type': 'received', 'sender': 'DR. JENKINS', 'time': '09:15 AM', 'text': 'Alex, thầy đã tải lên tài liệu ôn tập cho bài kiểm tra giữa kỳ.' },
      { 'id': 2, 'type': 'received', 'sender': 'DR. JENKINS', 'time': '09:16 AM', 'file': 'Calculus_Midterm_Review.pdf', 'size': '2.4 MB', 'fileType': 'pdf' },
      { 'id': 3, 'type': 'sent', 'sender': 'YOU', 'time': '09:45 AM', 'text': 'Dạ em đã thấy rồi ạ. Em cảm ơn thầy! Em có một câu hỏi về phần Tích phân bội ba...' },
      { 'id': 4, 'type': 'received', 'sender': 'DR. JENKINS', 'time': '10:02 AM', 'text': 'Cứ hỏi đi Alex. Đây là ví dụ trực quan về mặt bậc hai em cần lưu ý.' },
      { 'id': 5, 'type': 'received', 'sender': 'DR. JENKINS', 'time': '10:03 AM', 'file': 'Quadric_Surfaces_3D.jpg', 'size': '1.8 MB', 'fileType': 'image' },
    ]);
    final scrollController = useScrollController();
    final textController = useTextEditingController();

    void sendMessage() {
      if (textController.text.trim().isEmpty) return;
      messages.value = [
        ...messages.value,
        {
          'id': DateTime.now().millisecondsSinceEpoch,
          'type': 'sent',
          'sender': 'YOU',
          'time': 'Just now',
          'text': textController.text,
        }
      ];
      textController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Column(
      children: [
        // Chat Header
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: SchoolColors.darkBorder)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: SchoolColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'AC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: SchoolColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: SchoolColors.darkSurface, width: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Calculus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Active now • 42 students',
                      style: TextStyle(
                        fontSize: 13,
                        color: SchoolColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(icon: Icons.phone_outlined, onTap: () {}),
              const SizedBox(width: 12),
              _HeaderIconButton(icon: Icons.videocam_outlined, onTap: () {}),
            ],
          ),
        ),

        // Message Stream
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(40),
            itemCount: messages.value.length + 1, // +1 for typing indicator
            itemBuilder: (context, index) {
              if (index == messages.value.length) {
                return const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: _TypingIndicator(),
                );
              }

              final msg = messages.value[index];
              final isSent = msg['type'] == 'sent';

              return Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        msg['sender'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: SchoolColors.darkMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (msg['text'] != null)
                      _MessageBubble(text: msg['text'] as String, time: msg['time'] as String, isSent: isSent),
                    if (msg['file'] != null)
                      _AttachmentCard(
                        fileName: msg['file'] as String,
                        fileSize: msg['size'] as String,
                        fileType: msg['fileType'] as String,
                        isSent: isSent,
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Input Dock
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SchoolColors.darkBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _DockIconButton(icon: Icons.add_circle_outline, onTap: () {}),
                Expanded(
                  child: TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                    decoration: const InputDecoration(
                      hintText: 'Gửi tin nhắn cho lớp học...',
                      hintStyle: TextStyle(color: SchoolColors.darkMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                _DockIconButton(icon: Icons.emoji_emotions_outlined, onTap: () {}),
                EliteTactileButton(
                  onTap: sendMessage,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: SchoolColors.gradPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SchoolColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EliteTactileButton(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: SchoolColors.darkMuted, size: 24),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EliteTactileButton(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: SchoolColors.darkMuted, size: 24),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.time, required this.isSent});
  final String text;
  final String time;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: isSent ? null : Colors.white.withOpacity(0.04),
        gradient: isSent ? SchoolColors.gradPrimary : null,
        borderRadius: BorderRadius.circular(28).copyWith(
          bottomRight: isSent ? const Radius.circular(4) : null,
          bottomLeft: !isSent ? const Radius.circular(4) : null,
        ),
        border: Border.all(
          color: isSent ? SchoolColors.primary.withOpacity(0.3) : SchoolColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.isSent,
  });

  final String fileName;
  final String fileSize;
  final String fileType;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return EliteTactileButton(
      onTap: () {},
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: SchoolColors.darkBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SchoolColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                fileType == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                color: SchoolColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileSize,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SchoolColors.darkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download_rounded, color: SchoolColors.darkMuted),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends HookWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(3, (index) {
              final animation = Tween<double>(begin: 0.4, end: 1.0).animate(
                CurvedAnimation(
                  parent: controller,
                  curve: Interval(
                    index * 0.2,
                    0.6 + index * 0.2,
                    curve: Curves.easeInOut,
                  ),
                ),
              );
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.6 + (0.4 * (animation.value - 0.4) / 0.6),
                    child: Opacity(
                      opacity: animation.value,
                      child: Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          color: SchoolColors.darkMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(width: 8),
          const Text(
            'Dr. Jenkins is typing',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SchoolColors.darkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
