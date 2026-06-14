import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:school_world/main.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';

class EliteCampusChat extends HookWidget {
  const EliteCampusChat({super.key, this.initialRoomId, this.classId});
  final String? initialRoomId;
  final String? classId;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final selectedRoomId = useState<String?>(initialRoomId);
    
    // Fetch user's rooms
    var query = repo.firestore
        .collection('rooms')
        .where('userIds', arrayContains: repo.uid);
    
    if (classId != null) {
      query = query.where('metadata.classId', isEqualTo: classId);
    }
    
    final roomsSnap = useStream(useMemoized(() => query
        .orderBy('updatedAt', descending: true)
        .snapshots(), [repo.uid, classId]));

    // Auto-select first room if none selected
    useEffect(() {
      if (selectedRoomId.value == null && roomsSnap.hasData && roomsSnap.data!.docs.isNotEmpty) {
        selectedRoomId.value = roomsSnap.data!.docs.first.id;
      }
      return null;
    }, [roomsSnap.hasData]);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chat Explorer Sidebar
          SizedBox(
            width: 380,
            child: EliteNestedBezel(
              padding: EdgeInsets.zero,
              child: _ChatExplorer(
                roomsSnap: roomsSnap,
                selectedRoomId: selectedRoomId.value,
                onRoomSelect: (id) => selectedRoomId.value = id,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Main Chat View
          Expanded(
            child: EliteNestedBezel(
              padding: EdgeInsets.zero,
              child: selectedRoomId.value != null
                  ? _ChatView(roomId: selectedRoomId.value!)
                  : const Center(
                      child: EmptyStateWidget(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Select a conversation',
                        subtitle: 'Pick a room from the list to start chatting.',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatExplorer extends StatelessWidget {
  const _ChatExplorer({
    required this.roomsSnap,
    required this.selectedRoomId,
    required this.onRoomSelect,
  });

  final AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> roomsSnap;
  final String? selectedRoomId;
  final ValueChanged<String> onRoomSelect;

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
          child: !roomsSnap.hasData
              ? const Center(child: BrandedLoader())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: roomsSnap.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = roomsSnap.data!.docs[index];
                    final data = doc.data();
                    final name = data['name']?.toString() ?? 'Group';
                    final type = data['type']?.toString() ?? 'group';
                    
                    return _ChannelItem(
                      name: name,
                      initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
                      lastMessage: data['lastMessage']?.toString() ?? 'No messages yet',
                      unread: 0, // Logic for unread count can be added later
                      isOnline: false, // RTDB presence integration
                      color: _getColorForType(type),
                      isActive: selectedRoomId == doc.id,
                      onTap: () => onRoomSelect(doc.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getColorForType(String type) {
    if (type == 'class_main') return SchoolColors.primary;
    if (type == 'direct') return Colors.lightBlue;
    return SchoolColors.orange;
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
    required this.onTap,
    this.isActive = false,
  });

  final String name;
  final String initial;
  final String lastMessage;
  final int unread;
  final bool isOnline;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }
}

class _ChatView extends HookWidget {
  const _ChatView({required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final textController = useTextEditingController();
    
    final messagesSnap = useStream(useMemoized(() => repo.firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots(), [roomId]));

    final roomSnap = useFuture(useMemoized(() => repo.firestore.collection('rooms').doc(roomId).get(), [roomId]));
    final roomData = roomSnap.data?.data() ?? {};
    final roomName = roomData['name']?.toString() ?? 'Chat';

    void sendMessage() async {
      final text = textController.text.trim();
      if (text.isEmpty) return;
      
      final now = FieldValue.serverTimestamp();
      final msgData = {
        'authorId': repo.uid,
        'text': text,
        'createdAt': now,
        'type': 'text',
      };
      
      textController.clear();
      
      final batch = repo.firestore.batch();
      final msgRef = repo.firestore.collection('rooms').doc(roomId).collection('messages').doc();
      batch.set(msgRef, msgData);
      batch.update(repo.firestore.collection('rooms').doc(roomId), {
        'lastMessage': text,
        'updatedAt': now,
      });
      
      await batch.commit();
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
                child: Container(
                  decoration: BoxDecoration(
                    color: SchoolColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      roomName.isNotEmpty ? roomName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Live Collaboration',
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
          child: !messagesSnap.hasData
              ? const Center(child: BrandedLoader())
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(40),
                  itemCount: messagesSnap.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = messagesSnap.data!.docs[index];
                    final msg = doc.data();
                    final isSent = msg['authorId'] == repo.uid;
                    final createdAt = (msg['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final timeStr = DateFormat('hh:mm a').format(createdAt);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isSent)
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                               child: StudentName(
                                 studentId: msg['authorId']?.toString() ?? '',
                                 style: const TextStyle(
                                   fontSize: 11,
                                   fontWeight: FontWeight.w900,
                                   color: SchoolColors.darkMuted,
                                   letterSpacing: 1.2,
                                 ),
                               ),
                             ),
                          if (msg['text'] != null)
                            _MessageBubble(text: msg['text'] as String, time: timeStr, isSent: isSent),
                          if (msg['fileUrl'] != null)
                             _AttachmentCard(
                               fileName: msg['fileName']?.toString() ?? 'File',
                               fileSize: msg['fileSize']?.toString() ?? '',
                               fileType: msg['fileType']?.toString() ?? 'file',
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
                      hintText: 'Gửi tin nhắn...',
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
        decoration: const BoxDecoration(
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
        decoration: const BoxDecoration(
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
