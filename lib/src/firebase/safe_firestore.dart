import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Wraps a stream to delay cancellation by 500ms.
/// This prevents the 'LateInitializationError' and 'Unexpected state (ID: b815 / ca9)'
/// in cloud_firestore_web when a stream is listened to and cancelled very quickly
/// (e.g. during rapid UI rebuilds or route pops).
Stream<T> safeFirebaseStream<T>(Stream<T> source) {
  late StreamController<T> controller;
  StreamSubscription<T>? subscription;

  controller = StreamController<T>.broadcast(
    onListen: () {
      subscription = source.listen(
        controller.add,
        onError: (error, stackTrace) {
          if (subscription != null) {
            // Suppress permission-denied errors if the user is unauthenticated (e.g. during/after logout)
            if (error is FirebaseException &&
                error.code == 'permission-denied' &&
                FirebaseAuth.instance.currentUser == null) {
              return;
            }
            controller.addError(error, stackTrace);
          }
        },
        onDone: controller.close,
      );
    },
    onCancel: () {
      final sub = subscription;
      subscription = null;
      if (sub != null) {
        // The magic fix: delay cancel to give Firebase JS SDK time to initialize!
        Future.delayed(const Duration(milliseconds: 500), () {
          sub.cancel();
        });
      }
    },
  );

  return controller.stream;
}

extension SafeQueryExtension<T> on Query<T> {
  Stream<QuerySnapshot<T>> safeSnapshots({bool includeMetadataChanges = false}) {
    return safeFirebaseStream(snapshots(includeMetadataChanges: includeMetadataChanges));
  }
}

extension SafeDocExtension<T> on DocumentReference<T> {
  Stream<DocumentSnapshot<T>> safeSnapshots({bool includeMetadataChanges = false}) {
    return safeFirebaseStream(snapshots(includeMetadataChanges: includeMetadataChanges));
  }
}
