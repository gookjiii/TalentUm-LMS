import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final webinarsProvider =
    StreamProvider.autoDispose.family<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
      (String, int)
    >((ref, arg) {
      final uid = ref.watch(uidProvider);
      if (uid == null) return Stream.value([]);
      final repo = ref.watch(repositoryProvider);
      final classesAsync = ref.watch(studentClassesStreamProvider);
      final classIds = classesAsync.value?.map((c) => c['id'] as String).toList() ?? [];

      if (arg.$1.isEmpty) {
        if (classIds.isEmpty) return Stream.value([]);
        return repo
            .webinarsForClasses(classIds, limit: arg.$2)
            .map((snapshot) => snapshot.docs);
      }
      return repo.webinarsForClass(arg.$1, limit: arg.$2).map((snapshot) => snapshot.docs);
    });
