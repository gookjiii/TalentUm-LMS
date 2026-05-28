import 'dart:async';
import 'dart:convert';
import 'package:school_world/src/firebase/safe_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FirebaseChatController extends InMemoryChatController with ChangeNotifier {
  final FirebaseFirestore firestore;
  final ValueNotifier<int> searchRevision = ValueNotifier<int>(0);
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  Listenable get searchListenable => searchRevision;
  void _notifySearchChanged() => searchRevision.value++;

  final String roomId;
  String? _topicId;
  String? get currentTopicId => _topicId;
  String? _attachmentType;
  final void Function(List<Message>)? onMessagesUpdated;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<Message> _allMessages = [];
  String _searchQuery = '';
  List<String> _searchResults = [];
  int _searchIndex = -1;

  List<String> get searchResults => _searchResults;
  int get searchIndex => _searchIndex;
  String get searchQuery => _searchQuery;

  static const int _pageSize = 30;
  DocumentSnapshot<Map<String, dynamic>>? _oldestLoadedDoc;
  bool _hasMoreOlder = true;
  bool _isLoadingOlder = false;
  // Optimistic reaction overlay; map<messageId, reactions map>
  final Map<String, Map<String, dynamic>> _pendingReactions = {};

  FirebaseChatController({
    required this.firestore,
    required this.roomId,
    String? topicId,
    this.onMessagesUpdated,
  }) : _topicId = topicId;

  void setTopicId(String? topicId) {
    if (_topicId == topicId) return;
    _topicId = topicId;
    _allMessages = []; // Clear current messages for new topic
    stopListening();
    startListening();
  }

  void setAttachmentType(String? type) {
    if (_attachmentType == type) return;
    _attachmentType = type;
    _applySearch(animated: false);
  }

  Future<void> pinMessage(String messageId) async {
    final ref = firestore.collection('rooms').doc(roomId);
    await ref.update({
      'pinnedMessageIds': FieldValue.arrayUnion([messageId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unpinMessage(String messageId) async {
    final ref = firestore.collection('rooms').doc(roomId);
    await ref.update({
      'pinnedMessageIds': FieldValue.arrayRemove([messageId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void startListening() {
    _sub?.cancel();

    // 1. Load from cache immediately for instant UI
    _loadFromCache();

    // 2. Subscribe to the most recent _pageSize messages with realtime updates.
    _sub = safeFirebaseStream(
      firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .snapshots(),
    ).listen(
      _onSnapshot,
      onError: (e) {
        // Non-fatal: stream will retry on reconnect
      },
    );
  }

  void _loadFromCache() {
    try {
      if (!Hive.isBoxOpen('chat_cache')) return;
      final box = Hive.box('chat_cache');
      final cached = box.get('msgs_$roomId');
      if (cached != null && cached is String) {
        final List<dynamic> list = jsonDecode(cached);
        final cachedMessages = list
            .map(
              (d) => toMessage(d['id'] as String, Map<String, dynamic>.from(d)),
            )
            .toList();
        _allMessages = cachedMessages;
        _applySearch(animated: false);
      }
    } catch (_) {}
  }

  // Recursively converts Firestore-specific types (Timestamp, GeoPoint) to
  // JSON-safe primitives so jsonEncode never throws on cached message metadata.
  static Object? _toJsonSafe(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is Map)
      return {
        for (final e in value.entries) e.key.toString(): _toJsonSafe(e.value),
      };
    if (value is List) return [for (final v in value) _toJsonSafe(v)];
    return value;
  }

  void _saveToCache() {
    try {
      if (!Hive.isBoxOpen('chat_cache')) return;
      final box = Hive.box('chat_cache');
      // Save last 50 messages
      final toSave = _allMessages.reversed.take(50).toList().reversed.map((m) {
        return {
          'id': m.id,
          'authorId': m.authorId,
          'type': m is ImageMessage
              ? 'image'
              : (m is FileMessage ? 'file' : 'text'),
          'uri': m is ImageMessage
              ? m.source
              : (m is FileMessage ? m.source : null),
          'name': m is FileMessage ? m.name : null,
          'text': m is TextMessage ? m.text : (m.metadata?['text'] ?? ''),
          'size': m is ImageMessage ? m.size : (m is FileMessage ? m.size : null),
          'metadata': _toJsonSafe(m.metadata),
          'createdAt': m.createdAt?.millisecondsSinceEpoch,
        };
      }).toList();
      box.put('msgs_$roomId', jsonEncode(toSave));
    } catch (_) {}
  }

  bool get hasMoreOlder => _hasMoreOlder;

  /// Fetches an older page (pre-pagination) of messages. Idempotent and safe
  /// to call repeatedly; will no-op if a page is already loading or if there
  /// are no more messages to fetch.
  Future<void> loadOlder() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;
    if (_oldestLoadedDoc == null) return;
    _isLoadingOlder = true;
    try {
      final snap = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_oldestLoadedDoc!)
          .limit(_pageSize)
          .get();
      if (isDisposed) return;
      if (snap.docs.isEmpty) {
        _hasMoreOlder = false;
        return;
      }
      if (snap.docs.length < _pageSize) {
        _hasMoreOlder = false;
      }
      _oldestLoadedDoc = snap.docs.last;
      final List<Message> olderMessages = snap.docs.reversed
          .map<Message>(
            (dynamic doc) => toMessage(doc.id, _sanitizeFirestoreValue(doc.data()) as Map<String, dynamic>),
          )
          .toList();
      _allMessages = [...olderMessages, ..._allMessages];
      await _applySearch(animated: false);
      if (isDisposed) return;
      onMessagesUpdated?.call(List.unmodifiable(messages));
    } finally {
      _isLoadingOlder = false;
    }
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
    if (isDisposed) return;
    // Reverse docs from descending query to get [oldest ... newest]
    final docs = snap.docs.reversed.toList();
    if (docs.isEmpty) {
      _allMessages = [];
      _saveToCache();
      await _applySearch(animated: false);
      if (isDisposed) return;
      onMessagesUpdated?.call(List.unmodifiable(messages));
      return;
    }

    _oldestLoadedDoc = snap.docs.last; // last in descending = oldest
    // Map docs to Message domain objects; reconcile pending reaction overlay.
    final List<Message> recentMessages = docs.map<Message>((dynamic doc) {
      final data = _sanitizeFirestoreValue(doc.data()) as Map<String, dynamic>;
      final pending = _pendingReactions[doc.id];
      if (pending != null) {
        final serverReactions = data['reactions'] as Map?;
        if (_reactionsEqual(serverReactions, pending)) {
          _pendingReactions.remove(doc.id);
        } else {
          data['reactions'] = pending;
        }
      }
      return toMessage(doc.id, data);
    }).toList();

    // Merge with already-fetched older messages.
    final recentIds = recentMessages.map((m) => m.id).toSet();
    final preserved = _allMessages
        .where((m) => !recentIds.contains(m.id))
        .toList();

    // Combine: [preserved_older ... older_recent ... newest_recent]
    _allMessages = [...preserved, ...recentMessages];

    // Optimized sort: ensure oldest at index 0, newest at end
    _allMessages.sort((a, b) {
      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ta.compareTo(tb);
    });

    _saveToCache();
    await _applySearch(animated: false);
    if (isDisposed) return;
    onMessagesUpdated?.call(List.unmodifiable(messages));
  }

  bool _reactionsEqual(Map? a, Map? b) {
    final ma = Map<String, dynamic>.from(a ?? {});
    final mb = Map<String, dynamic>.from(b ?? {});
    if (ma.length != mb.length) return false;
    for (final entry in ma.entries) {
      final other = mb[entry.key];
      if (other == null) return false;
      final l1 = List<String>.from(entry.value as List? ?? const []);
      final l2 = List<String>.from(other as List? ?? const []);
      if (l1.length != l2.length) return false;
      final s1 = l1.toSet();
      if (!s1.containsAll(l2)) return false;
    }
    return true;
  }

  Future<void> setSearchQuery(String query) async {
    final next = query.trim().toLowerCase();
    if (next == _searchQuery) return;
    _searchQuery = next;
    await _applySearch(animated: false);

    if (_searchResults.isNotEmpty) {
      _searchIndex =
          _searchResults.length - 1; // Start with the most recent match
      scrollToMessage(_searchResults[_searchIndex]);
    } else {
      _searchIndex = -1;
    }
    onMessagesUpdated?.call(List.unmodifiable(messages));
    _notifySearchChanged();
  }

  void searchNext() {
    if (_searchResults.isEmpty) return;
    _searchIndex = (_searchIndex - 1);
    if (_searchIndex < 0) _searchIndex = _searchResults.length - 1;
    scrollToMessage(_searchResults[_searchIndex]);
    onMessagesUpdated?.call(List.unmodifiable(messages));
    _notifySearchChanged();
  }

  void searchPrevious() {
    if (_searchResults.isEmpty) return;
    _searchIndex = (_searchIndex + 1) % _searchResults.length;
    scrollToMessage(_searchResults[_searchIndex]);
    onMessagesUpdated?.call(List.unmodifiable(messages));
    _notifySearchChanged();
  }

  Message? getMessageById(String id) {
    try {
      return _allMessages.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  void jumpToSearchIndex(int index) {
    if (index < 0 || index >= _searchResults.length) return;
    _searchIndex = index;
    scrollToMessage(_searchResults[_searchIndex]);
    _notifySearchChanged();
  }

  Future<void> updateReactionOptimistically({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final sourceMessages = _allMessages.isEmpty ? messages : _allMessages;
    final index = sourceMessages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index == -1) return;

    final message = sourceMessages[index];
    final metadata = Map<String, dynamic>.from(message.metadata ?? {});
    final reactions = Map<String, dynamic>.from(metadata['reactions'] ?? {});
    final userList = List<String>.from(reactions[emoji] ?? []);

    if (userList.contains(userId)) {
      userList.remove(userId);
    } else {
      userList.add(userId);
    }

    if (userList.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = userList;
    }
    metadata['reactions'] = reactions;

    final updatedMessages = List<Message>.from(sourceMessages);
    final updatedMessage = _copyMessageWithMetadata(message, metadata);
    updatedMessages[index] = updatedMessage;
    _allMessages = List.from(updatedMessages);
    _pendingReactions[messageId] = Map<String, dynamic>.from(reactions);
    final visibleIndex = messages.indexWhere((m) => m.id == messageId);
    if (visibleIndex != -1) {
      final visibleOldMessage = messages[visibleIndex];
      await removeMessage(visibleOldMessage, animated: false);
      await insertMessage(updatedMessage, index: visibleIndex, animated: false);
    } else {
      await _applySearch(animated: false);
    }
    onMessagesUpdated?.call(List.unmodifiable(messages));
  }

  Message _copyMessageWithMetadata(
    Message message,
    Map<String, dynamic> metadata,
  ) {
    if (message is TextMessage) {
      return Message.text(
        id: message.id,
        authorId: message.authorId,
        text: message.text,
        createdAt: message.createdAt,
        metadata: metadata,
      );
    }
    if (message is ImageMessage) {
      return Message.image(
        id: message.id,
        authorId: message.authorId,
        source: message.source,
        size: message.size,
        createdAt: message.createdAt,
        metadata: metadata,
      );
    }
    if (message is FileMessage) {
      return Message.file(
        id: message.id,
        authorId: message.authorId,
        source: message.source,
        name: message.name,
        size: message.size,
        createdAt: message.createdAt,
        metadata: metadata,
      );
    }
    return message;
  }

  Future<void> _applySearch({bool animated = false}) async {
    if (isDisposed) return;
    List<Message> filtered = _allMessages;

    // 1. Topic filtering (Local)
    if (_topicId != null) {
      filtered = filtered
          .where((m) => m.metadata?['topicId'] == _topicId)
          .toList();
    } else {
      // General chat: show messages with NO topicId (null or missing)
      filtered = filtered.where((m) => m.metadata?['topicId'] == null).toList();
    }

    // 2. Attachment filtering (Local)
    if (_attachmentType != null) {
      filtered = filtered
          .where((m) => m.metadata?['attachmentType'] == _attachmentType)
          .toList();
    }

    // 3. Search query tracking (Local)
    if (_searchQuery.isNotEmpty) {
      _searchResults = filtered
          .where((message) {
            if (message is TextMessage) {
              return message.text.toLowerCase().contains(_searchQuery);
            }
            if (message is FileMessage) {
              return message.name.toLowerCase().contains(_searchQuery);
            }
            return false;
          })
          .map((m) => m.id)
          .toList();
    } else {
      _searchResults = [];
      _searchIndex = -1;
    }

    await setMessages(filtered, animated: animated);
    if (isDisposed) return;
    if (_searchQuery.isNotEmpty) _notifySearchChanged();
  }

  static dynamic _sanitizeFirestoreValue(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value;
    }

    if (kIsWeb) {
      try {
        final dynamic jsObj = value;
        if (jsObj != null && jsObj.seconds != null && jsObj.nanoseconds != null) {
          return Timestamp(jsObj.seconds as int, jsObj.nanoseconds as int);
        }
      } catch (_) {}
    }

    if (value is Map) {
      final Map<String, dynamic> result = {};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        result[key] = _sanitizeFirestoreValue(entry.value);
      }
      return result;
    }

    if (value is List) {
      return [for (final item in value) _sanitizeFirestoreValue(item)];
    }

    if (kIsWeb) {
      try {
        if (value is Iterable) {
          return [for (final item in value) _sanitizeFirestoreValue(item)];
        }
      } catch (_) {}
    }

    return value;
  }

  Message toMessage(String id, Map<String, dynamic> rawData) {
    final d = _sanitizeFirestoreValue(rawData) as Map<String, dynamic>;
    final authorId = (d['authorId'] as String?) ?? '';
    final createdAt =
        readDate(d['createdAt']) ??
        readDate(d['clientCreatedAt']) ??
        readDate(d['updatedAt']) ??
        DateTime.now();
    final meta = Map<String, dynamic>.from(
      _toJsonSafe(d['metadata'] as Map? ?? {}) as Map? ?? {},
    );
    // Merge reactions and text from top-level fields into metadata
    if (d['reactions'] != null) meta['reactions'] = _toJsonSafe(d['reactions']);
    if (d['text'] != null) meta['text'] = d['text'];

    final type = d['type'] as String? ?? 'text';
    if (type == 'audio') meta['type'] = 'audio';
    
    final statusStr = (meta['status'] as String?) ?? (d['status'] as String?);
    final status = switch (statusStr) {
      'sending' => MessageStatus.sending,
      'sent' => MessageStatus.sent,
      'error' => MessageStatus.error,
      'delivered' => MessageStatus.delivered,
      'seen' => MessageStatus.seen,
      _ => null,
    };

    switch (type) {
      case 'image':
        return Message.image(
          id: id,
          authorId: authorId,
          source: d['uri'] as String? ?? '',
          size: (d['size'] as num?)?.toInt(),
          createdAt: createdAt,
          metadata: meta,
          status: status,
        );
      case 'audio':
      case 'file':
      case 'video':
        return Message.file(
          id: id,
          authorId: authorId,
          source: d['uri'] as String? ?? '',
          name: d['name'] as String? ?? '',
          size: (d['size'] as num?)?.toInt(),
          createdAt: createdAt,
          metadata: meta,
          status: status,
        );
      default:
        return Message.text(
          id: id,
          authorId: authorId,
          text: d['text'] as String? ?? '',
          createdAt: createdAt,
          metadata: meta,
          status: status,
        );
    }
  }

  DateTime? readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Future<void> sendText(
    String authorId,
    String text, {
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    final ref = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc();
    final messageId = ref.id;
    final clientCreatedAt = DateTime.now();

    final finalMetadata = Map<String, dynamic>.from(
      _toJsonSafe(metadata ?? {}) as Map? ?? {},
    );
    if (_topicId != null) {
      finalMetadata['topicId'] = _topicId;
    }
    if (replyToId != null) {
      finalMetadata['replyToId'] = replyToId;
      final repliedMsg = getMessageById(replyToId);
      if (repliedMsg is TextMessage) {
        finalMetadata['replyText'] = repliedMsg.text;
      }
    }
    finalMetadata['status'] = 'sending';

    // 1. Optimistic Update
    final optimisticMessage = Message.text(
      id: messageId,
      authorId: authorId,
      text: text,
      createdAt: clientCreatedAt,
      metadata: finalMetadata,
    );
    _allMessages = [..._allMessages, optimisticMessage];
    await _applySearch(animated: false);
    onMessagesUpdated?.call(List.unmodifiable(messages));

    try {
      await ref.set({
        'type': 'text',
        'authorId': authorId,
        'text': text,
        'metadata': {...finalMetadata, 'status': 'sent'},
        'clientCreatedAt': Timestamp.fromDate(clientCreatedAt),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Update parent room updatedAt
      await firestore.collection('rooms').doc(roomId).set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Update local status to error
      final index = _allMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = Message.text(
          id: messageId,
          authorId: authorId,
          text: text,
          createdAt: clientCreatedAt,
          metadata: {...finalMetadata, 'status': 'error'},
        );
        _allMessages = List.from(_allMessages)..[index] = updated;
        await _applySearch(animated: false);
        onMessagesUpdated?.call(List.unmodifiable(messages));
      }
    }
  }

  Future<void> sendFile({
    required String authorId,
    required String uri,
    required String name,
    required int size,
    required String type,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    final ref = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc();
    final messageId = ref.id;
    final clientCreatedAt = DateTime.now();

    final finalMetadata = Map<String, dynamic>.from(
      _toJsonSafe(metadata ?? {}) as Map? ?? {},
    );
    if (_topicId != null) {
      finalMetadata['topicId'] = _topicId;
    }
    if (replyToId != null) {
      finalMetadata['replyToId'] = replyToId;
      final repliedMsg = getMessageById(replyToId);
      if (repliedMsg is TextMessage) {
        finalMetadata['replyText'] = repliedMsg.text;
      }
    }
    finalMetadata['status'] = 'sending';

    // 1. Optimistic Update
    final optimisticMessage = type == 'image'
        ? Message.image(
            id: messageId,
            authorId: authorId,
            source: uri,
            size: size,
            createdAt: clientCreatedAt,
            metadata: finalMetadata,
          )
        : Message.file(
            id: messageId,
            authorId: authorId,
            source: uri,
            name: name,
            size: size,
            createdAt: clientCreatedAt,
            metadata: finalMetadata,
          );

    _allMessages = [..._allMessages, optimisticMessage];
    await _applySearch(animated: false);
    onMessagesUpdated?.call(List.unmodifiable(messages));

    try {
      await ref.set({
        'type': type,
        'authorId': authorId,
        'uri': uri,
        'name': name,
        'size': size,
        'metadata': {...finalMetadata, 'status': 'sent'},
        'clientCreatedAt': Timestamp.fromDate(clientCreatedAt),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await firestore.collection('rooms').doc(roomId).set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Update local status to error
      final index = _allMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = type == 'image'
            ? Message.image(
                id: messageId,
                authorId: authorId,
                source: uri,
                size: size,
                createdAt: clientCreatedAt,
                metadata: {...finalMetadata, 'status': 'error'},
              )
            : Message.file(
                id: messageId,
                authorId: authorId,
                source: uri,
                name: name,
                size: size,
                createdAt: clientCreatedAt,
                metadata: {...finalMetadata, 'status': 'error'},
              );
        _allMessages = List.from(_allMessages)..[index] = updated;
        await _applySearch(animated: false);
        onMessagesUpdated?.call(List.unmodifiable(messages));
      }
    }
  }

  Future<void> editText(String messageId, String newText) async {
    final index = _allMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _allMessages[index];
      if (message is TextMessage) {
        final metadata = Map<String, dynamic>.from(message.metadata ?? {});
        metadata['isEdited'] = true;
        metadata['editedAt'] = DateTime.now().millisecondsSinceEpoch;

        final editedMessage = message.copyWith(
          text: newText,
          metadata: metadata,
          updatedAt: DateTime.now(),
        );

        _allMessages = List<Message>.from(_allMessages)..[index] = editedMessage;
        await _applySearch(animated: false);
        _saveToCache();
        onMessagesUpdated?.call(List.unmodifiable(messages));
      }
    }

    final ref = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId);
    await ref.update({
      'text': newText,
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata.isEdited': true,
      'metadata.editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String messageId) async {
    final index = _allMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _allMessages[index];
      final metadata = Map<String, dynamic>.from(message.metadata ?? {});
      metadata['isDeleted'] = true;
      metadata['deletedAt'] = DateTime.now().millisecondsSinceEpoch;

      final deletedMessage = message.copyWith(
        metadata: metadata,
        updatedAt: DateTime.now(),
      );

      _allMessages = List<Message>.from(_allMessages)..[index] = deletedMessage;
      await _applySearch(animated: false);
      _saveToCache();
      onMessagesUpdated?.call(List.unmodifiable(messages));
    }

    final ref = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId);
    await ref.update({
      'text': 'Сообщение удалено',
      'metadata.isDeleted': true,
      'metadata.deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTypingStatus(String userId, bool isTyping) async {
    final ref = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('typing')
        .doc(userId);

    if (isTyping) {
      await ref.set({
        'isTyping': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  Stream<List<String>> typingUsersStream(String currentUserId) {
    final tenSecondsAgo = DateTime.now().subtract(const Duration(seconds: 10));
    return firestore
        .collection('rooms')
        .doc(roomId)
        .collection('typing')
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(tenSecondsAgo))
        .snapshots()
        .map((snap) {
          return snap.docs
              .where((doc) => doc.id != currentUserId)
              .map((doc) => doc.id)
              .toList();
        });
  }

  Future<void> sendAudio({
    required String authorId,
    required String uri,
    required Duration duration,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    final ref = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .doc();
    final messageId = ref.id;
    final clientCreatedAt = DateTime.now();

    final finalMetadata = Map<String, dynamic>.from(
      _toJsonSafe(metadata ?? {}) as Map? ?? {},
    );
    if (_topicId != null) {
      finalMetadata['topicId'] = _topicId;
    }
    if (replyToId != null) {
      finalMetadata['replyToId'] = replyToId;
      final repliedMsg = getMessageById(replyToId);
      if (repliedMsg is TextMessage) {
        finalMetadata['replyText'] = repliedMsg.text;
      }
    }
    finalMetadata['durationMs'] = duration.inMilliseconds;
    finalMetadata['type'] = 'audio';

    // 1. Optimistic Update
    final optimisticMessage = Message.file(
      id: messageId,
      authorId: authorId,
      source: uri,
      name: 'Голосовое сообщение',
      size: 0,
      createdAt: clientCreatedAt,
      metadata: {...finalMetadata, 'status': 'sending'},
    );
    _allMessages = [..._allMessages, optimisticMessage];
    await _applySearch(animated: false);
    onMessagesUpdated?.call(List.unmodifiable(messages));

    try {
      await ref.set({
        'type': 'audio',
        'authorId': authorId,
        'uri': uri,
        'name': 'Голосовое сообщение',
        'metadata': {...finalMetadata, 'status': 'sent'},
        'clientCreatedAt': Timestamp.fromDate(clientCreatedAt),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await firestore.collection('rooms').doc(roomId).set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _allMessages.removeWhere((m) => m.id == messageId);
      await _applySearch(animated: false);
      onMessagesUpdated?.call(List.unmodifiable(messages));
      rethrow;
    }
  }

  void stopListening() {
    if (_sub != null) {
      // On Web, cancelling a subscription immediately after creating it
      // can throw LateInitializationError because the interop internal
      // 'onSnapshotUnsubscribe' hasn't been assigned yet.
      final sub = _sub!;
      _sub = null;
      if (kIsWeb) {
        // Use a small delay to ensure the subscription has finished its setup
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            sub.cancel();
          } catch (e) {
            debugPrint(
              'FirebaseChatController: Error cancelling subscription on Web: $e',
            );
          }
        });
      } else {
        sub.cancel();
      }
    }
  }

  @override
  Future<void> setMessages(List<Message> messages, {bool animated = false}) async {
    await super.setMessages(messages, animated: animated);
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    searchRevision.dispose();
    stopListening();
    super.dispose();
  }
}
