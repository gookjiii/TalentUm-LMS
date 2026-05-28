import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../models/schedule.dart';
import 'package:school_world/src/features/chat/data/firebase_chat_controller.dart';
import '../firebase/school_repository.dart';

import 'package:school_world/src/firebase/storage_provider.dart';

final repositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository();
});

final storageProvider = Provider<StorageProvider>((ref) {
  return CloudinaryStorageProvider.fromEnvironmentOrFirebase();
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
    ChangeNotifierProvider.family<FirebaseChatController, String>((ref, roomId) {
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
    if (uid == null) return Stream.value([]);
    final repo = ref.watch(repositoryProvider);
    return repo.studentClassesCached();
  },
);

final teacherClassesStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final uid = ref.watch(uidProvider);
    if (uid == null) return Stream.value([]);
    final appState = ref.watch(schoolAppStateProvider);
    final repo = ref.watch(repositoryProvider);
    
    if (appState.isLeadTeacher) {
      return repo.firestore
          .collection('classes')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
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
