import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../models/schedule.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import '../firebase/school_repository.dart';

import 'package:school_world/src/firebase/storage_provider.dart';

final repositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository();
});

/// Firebase for small materials; Google Drive for large files when configured.
final libraryStorageProvider = Provider<StorageProvider>((ref) {
  return CloudinaryStorageProvider.libraryProvider();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.authState();
});

final uidProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

final schoolAppStateProvider = ChangeNotifierProvider<SchoolAppState>((ref) {
  return SchoolAppState();
});

final preloadedChatControllerProvider =
    ChangeNotifierProvider.family<FirebaseChatController, String>((
      ref,
      roomId,
    ) {
      final uid = ref.watch(uidProvider);
      final repo = ref.watch(repositoryProvider);
      final controller = FirebaseChatController(
        firestore: repo.firestore,
        roomId: roomId,
      );
      if (uid != null) {
        controller.startListening();
      }
      // ChangeNotifierProvider disposes the controller automatically —
      // no manual ref.onDispose needed.
      return controller;
    });

final studentClassesStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final uid = ref.watch(uidProvider);
    if (uid == null) return const Stream.empty();
    final repo = ref.watch(repositoryProvider);
    return repo.studentClassesCached();
  },
);

final teacherClassesStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final uid = ref.watch(uidProvider);
    if (uid == null) return const Stream.empty();

    final isTeacher = ref.watch(
      schoolAppStateProvider.select((s) => s.isTeacher),
    );
    if (!isTeacher) return const Stream.empty();

    final isLeadTeacher = ref.watch(
      schoolAppStateProvider.select((s) => s.isLeadTeacher),
    );
    final repo = ref.watch(repositoryProvider);

    if (isLeadTeacher) {
      return repo.firestore
          .collection('classes')
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
          );
    }

    return repo.teacherClassesCached();
  },
);

final studentSchedulesProvider = StreamProvider<List<ScheduleEntry>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final classesAsync = ref.watch(studentClassesStreamProvider);
  final classIds =
      classesAsync.value?.map((c) => c['id'].toString()).toList() ?? [];
  return repo.studentSchedulesStream(classIds);
});

final studentScheduleOverridesProvider = StreamProvider<List<ScheduleOverride>>(
  (ref) {
    final repo = ref.watch(repositoryProvider);
    final classesAsync = ref.watch(studentClassesStreamProvider);
    final classIds =
        classesAsync.value?.map((c) => c['id'].toString()).toList() ?? [];
    return repo.studentScheduleOverridesStream(classIds);
  },
);

final studentTodaySchedulesProvider = Provider<List<ResolvedScheduleItem>>((
  ref,
) {
  final schedules = ref.watch(studentSchedulesProvider).value ?? [];
  final overrides = ref.watch(studentScheduleOverridesProvider).value ?? [];
  final now = DateTime.now();
  return resolveDay(date: now, schedules: schedules, overrides: overrides);
});

final userDocumentProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value({});
  final repo = ref.watch(repositoryProvider);
  return repo.firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data() ?? {});
});

final userDataProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) {
      final repo = ref.watch(repositoryProvider);
      return repo.firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) => doc.data());
    });

/// Identifies which part of a group chat owns an unread indicator.
///
/// `allTopics` is used by the class/chat list: any unread message in the room
/// should light up the group. Topic sidebar items set it to false so that the
/// main chat and every topic have independent badges.
class ChatUnreadTarget {
  const ChatUnreadTarget({
    required this.roomOrClassId,
    this.topicId,
    this.allTopics = true,
  });

  final String roomOrClassId;
  final String? topicId;
  final bool allTopics;

  @override
  bool operator ==(Object other) {
    return other is ChatUnreadTarget &&
        other.roomOrClassId == roomOrClassId &&
        other.topicId == topicId &&
        other.allTopics == allTopics;
  }

  @override
  int get hashCode => Object.hash(roomOrClassId, topicId, allTopics);
}

final chatUnreadProvider = StreamProvider.family<bool, ChatUnreadTarget>((
  ref,
  target,
) {
  final uid = ref.watch(uidProvider);
  if (uid == null || target.roomOrClassId.isEmpty) {
    return Stream.value(false);
  }

  final repo = ref.watch(repositoryProvider);
  return _watchChatUnread(firestore: repo.firestore, target: target, uid: uid);
});

/// Backwards-compatible room-level provider used by the desktop sidebars and
/// chat cards. Room-level badges include messages posted in any topic.
final roomUnreadProvider = StreamProvider.family<bool, String>((ref, roomId) {
  return ref.watch(
    chatUnreadProvider(ChatUnreadTarget(roomOrClassId: roomId)).stream,
  );
});

Stream<bool> _watchChatUnread({
  required FirebaseFirestore firestore,
  required ChatUnreadTarget target,
  required String uid,
}) async* {
  try {
    var roomId = target.roomOrClassId;
    final directRoom = await firestore.collection('rooms').doc(roomId).get();

    // Some older class records store the class ID instead of the generated
    // room ID. Resolve that legacy shape before starting the live listener.
    if (!directRoom.exists) {
      final roomQuery = await firestore
          .collection('rooms')
          .where('metadata.classId', isEqualTo: target.roomOrClassId)
          .limit(1)
          .get();
      if (roomQuery.docs.isEmpty) {
        yield false;
        return;
      }
      roomId = roomQuery.docs.first.id;
    }

    // Query recent messages by createdAt descending (requires no composite indexes).
    // Filtering by topic or main chat is handled locally for 100% reliability.
    final query = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50);

    await for (final snap in query.snapshots()) {
      final Map<String, dynamic>? message;
      if (target.allTopics) {
        message = snap.docs.isEmpty ? null : snap.docs.first.data();
      } else if (target.topicId != null) {
        message = snap.docs
            .map((doc) => doc.data())
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (data) =>
                  data?['metadata'] is Map &&
                  (data?['metadata'] as Map)['topicId'] == target.topicId,
              orElse: () => null,
            );
      } else {
        // Main chat: show messages with NO topicId (null or missing)
        message = snap.docs
            .map((doc) => doc.data())
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (data) =>
                  data?['metadata'] is! Map ||
                  (data?['metadata'] as Map)['topicId'] == null,
              orElse: () => null,
            );
      }

      if (message == null) {
        yield false;
        continue;
      }

      final authorId = message['authorId']?.toString();
      if (authorId == uid) {
        yield false;
        continue;
      }

      final metadata = message['metadata'];
      final seenBy = metadata is Map ? metadata['seenBy'] : null;
      final hasSeen =
          seenBy is Iterable && seenBy.map((id) => id.toString()).contains(uid);
      yield !hasSeen;
    }
  } catch (_) {
    yield false;
  }
}
