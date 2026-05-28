import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_world/src/providers/app_providers.dart';

/// Mapping of emoji -> list of userIds that reacted with it.
typedef ReactionMap = Map<String, List<String>>;

/// Mapping of messageId -> [ReactionMap].
typedef RoomReactionsState = Map<String, ReactionMap>;

class ReactionsNotifier extends StateNotifier<RoomReactionsState> {
  ReactionsNotifier({required this.firestore, required this.roomId})
    : super(const {});

  final FirebaseFirestore firestore;
  final String roomId;

  /// Replace the reactions for [messageId] (e.g. when hydrating from a
  /// Firestore snapshot). No-op if already equal.
  void hydrate(String messageId, Map<String, dynamic>? rawReactions) {
    final next = _normalize(rawReactions);
    final current = state[messageId];
    if (_mapsEqual(current, next)) return;
    state = {...state, messageId: next};
  }

  /// Hydrate many messages at once (called from the Firestore snapshot).
  void hydrateAll(Map<String, Map<String, dynamic>?> messages) {
    final updated = <String, ReactionMap>{...state};
    var changed = false;
    messages.forEach((id, raw) {
      final next = _normalize(raw);
      if (!_mapsEqual(updated[id], next)) {
        updated[id] = next;
        changed = true;
      }
    });
    if (changed) state = updated;
  }

  /// Optimistically toggle [emoji] on [messageId] for [userId] and persist
  /// to Firestore in the background.
  Future<void> toggle({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final current = state[messageId] ?? const {};
    final next = <String, List<String>>{
      for (final entry in current.entries) entry.key: List.of(entry.value),
    };
    final users = List<String>.from(next[emoji] ?? const []);
    final shouldRemove = users.contains(userId);
    if (shouldRemove) {
      users.remove(userId);
    } else {
      users.add(userId);
    }
    if (users.isEmpty) {
      next.remove(emoji);
    } else {
      next[emoji] = users;
    }
    state = {...state, messageId: next};

    try {
      final docRef = firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId);
      await docRef.update({
        'reactions.$emoji': shouldRemove
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });
    } catch (_) {
      // Snapshot listener will re-hydrate and reconcile if write failed.
    }
  }

  ReactionMap _normalize(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const {};
    final normalized = <String, List<String>>{};
    for (final entry in raw.entries) {
      final users = List<String>.from(entry.value as List? ?? const []);
      if (users.isNotEmpty) normalized[entry.key] = users;
    }
    return normalized;
  }

  bool _mapsEqual(ReactionMap? a, ReactionMap? b) {
    final ma = a ?? const {};
    final mb = b ?? const {};
    if (ma.length != mb.length) return false;
    for (final entry in ma.entries) {
      final other = mb[entry.key];
      if (other == null) return false;
      if (other.length != entry.value.length) return false;
      final aSet = entry.value.toSet();
      if (!aSet.containsAll(other)) return false;
    }
    return true;
  }
}

final reactionsProvider =
    StateNotifierProvider.family<ReactionsNotifier, RoomReactionsState, String>(
      (ref, roomId) {
        final repo = ref.watch(repositoryProvider);
        return ReactionsNotifier(firestore: repo.firestore, roomId: roomId);
      },
    );
