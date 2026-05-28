import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_world/src/firebase/school_repository_schedules.dart';
import 'package:school_world/src/firebase/school_repository_feed.dart';
import 'package:school_world/src/firebase/school_repository_assignments.dart';
import 'package:school_world/src/firebase/school_repository_auth.dart';
import 'package:school_world/src/firebase/school_repository_classes.dart';
import 'package:school_world/src/firebase/school_repository_chat.dart';
import 'package:school_world/src/firebase/school_repository_presence.dart';
import 'package:school_world/src/firebase/school_repository_library.dart';
import 'package:school_world/src/firebase/school_repository_webinars.dart';
import 'package:school_world/src/firebase/school_repository_journal.dart';
import 'safe_firestore.dart';


export 'school_repository_schedules.dart';
export 'school_repository_feed.dart';
export 'school_repository_assignments.dart';
export 'school_repository_auth.dart';
export 'school_repository_classes.dart';
export 'school_repository_chat.dart';
export 'school_repository_presence.dart';
export 'school_repository_library.dart';
export 'school_repository_webinars.dart';
export 'school_repository_journal.dart';

class SchoolRepository
    with
        SchoolRepositorySchedules,
        SchoolRepositoryFeed,
        SchoolRepositoryAssignments,
        SchoolRepositoryAuth,
        SchoolRepositoryClasses,
        SchoolRepositoryChat,
        SchoolRepositoryPresence,
        SchoolRepositoryLibrary,
        SchoolRepositoryWebinars,
        SchoolRepositoryJournal {
  SchoolRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
    rtdb.FirebaseDatabase? database,
    GoogleSignIn? googleSignIn,
  }) : auth = auth ?? FirebaseAuth.instance,
       firestore = firestore ?? FirebaseFirestore.instance,
       functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
       storage = storage ?? FirebaseStorage.instance,
       database =
           database ??
           (kIsWeb
               ? rtdb.FirebaseDatabase.instanceFor(
                   app: Firebase.app(),
                   databaseURL:
                       'https://school-wolrd-default-rtdb.firebaseio.com',
                 )
               : rtdb.FirebaseDatabase.instance),
       googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  final FirebaseAuth auth;
  @override
  final FirebaseFirestore firestore;
  @override
  final FirebaseFunctions functions;
  @override
  final FirebaseStorage storage;
  @override
  final rtdb.FirebaseDatabase database;
  @override
  final GoogleSignIn googleSignIn;

  @override
  String? get uid => auth.currentUser?.uid;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream() {
    final id = uid;
    if (id == null) return const Stream.empty();
    return firestore.collection('users').doc(id).safeSnapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> systemSettingsStream() {
    return firestore.collection('settings').doc('system').safeSnapshots();
  }

  Future<void> updateSystemSettings({
    required String appName,
    String? logoUrl,
  }) async {
    await firestore.collection('settings').doc('system').set({
      'appName': appName,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox('app_settings');
    await Hive.openBox('cached_data');
  }

  Future<Map<String, dynamic>?> getCachedOrFetch(
    String collection,
    String id,
  ) async {
    final box = Hive.box('cached_data');
    final cacheKey = '$collection/$id';

    if (box.containsKey(cacheKey)) {
      try {
        return jsonDecode(box.get(cacheKey) as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    try {
      final doc = await firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        box.put(
          cacheKey,
          jsonEncode(
            data,
            toEncodable: (o) =>
                o is Timestamp ? o.toDate().toIso8601String() : o,
          ),
        );
        return data;
      }
    } catch (_) {}
    return null;
  }
}
