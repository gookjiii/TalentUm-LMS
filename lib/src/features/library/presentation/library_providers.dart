import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final libraryMaterialsProvider =
    StreamProvider.autoDispose.family<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
      String
    >((ref, classId) {
      final uid = ref.watch(uidProvider);
      if (uid == null) return Stream.value([]);
      final repo = ref.watch(repositoryProvider);
      return repo
          .libraryMaterialsForClass(classId)
          .map((snapshot) => snapshot.docs);
    });
