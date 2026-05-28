import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

mixin SchoolRepositoryPresence {
  FirebaseDatabase get database;
  String? get uid;

  /// Starts the presence monitoring for the current user.
  /// Sets them as 'online' in RTDB and 'offline' on disconnect.
  void startPresenceMonitoring() {
    final userId = uid;
    if (userId == null) return;

    final presenceRef = database.ref('status/$userId');

    database.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        // When we are connected, we can set our status to 'online'
        presenceRef
            .onDisconnect()
            .set({'state': 'offline', 'lastSeen': ServerValue.timestamp})
            .then((_) {
              presenceRef.set({
                'state': 'online',
                'lastSeen': ServerValue.timestamp,
              });
            });
      }
    });
  }

  /// Returns a stream of a user's presence status.
  Stream<Map<String, dynamic>> userStatusStream(String userId) {
    return database.ref('status/$userId').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {'state': 'offline'};
      return Map<String, dynamic>.from(data);
    });
  }

  /// Sets the typing status for the current user in a specific room.
  Future<void> setTypingStatus(String roomId, bool isTyping) async {
    final userId = uid;
    if (userId == null) return;

    final typingRef = database.ref('typing/$roomId/$userId');
    if (isTyping) {
      await typingRef.set(true);
      await typingRef.onDisconnect().remove();
    } else {
      await typingRef.remove();
    }
  }

  /// Returns a stream of users currently typing in a room.
  Stream<List<String>> typingUsersStream(String roomId) {
    return database.ref('typing/$roomId').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];
      return data.keys.cast<String>().where((id) => id != uid).toList();
    });
  }
}
