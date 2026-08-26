import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/schedule.dart';
import 'safe_firestore.dart';

mixin SchoolRepositorySchedules {
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;

  /// Returns schedules owned by [teacherId] and schedules attached to classes
  /// the teacher belongs to. Administrators often create a class schedule on
  /// behalf of another teacher, so filtering only by `teacherId` hides those
  /// lessons from the assigned teacher.
  Stream<List<ScheduleEntry>> teacherSchedulesStream(
    String teacherId, {
    Iterable<String>? classIds,
  }) {
    if (teacherId.trim().isEmpty) return Stream.value(const []);

    final explicitClassIds = _normaliseIds(classIds);
    final classIdsStream = _teacherClassIdsStream(teacherId);

    return classIdsStream.asyncExpand(
      (storedClassIds) => _teacherScheduleQueries(teacherId, {
        ...storedClassIds,
        ...explicitClassIds,
      }),
    );
  }

  Stream<List<ScheduleOverride>> teacherScheduleOverridesStream(
    String teacherId, {
    Iterable<String>? classIds,
  }) {
    if (teacherId.trim().isEmpty) return Stream.value(const []);

    final explicitClassIds = _normaliseIds(classIds);
    final classIdsStream = _teacherClassIdsStream(teacherId);

    return classIdsStream.asyncExpand(
      (storedClassIds) => _teacherOverrideQueries(teacherId, {
        ...storedClassIds,
        ...explicitClassIds,
      }),
    );
  }

  Stream<List<ScheduleEntry>> _teacherScheduleQueries(
    String teacherId,
    Set<String> classIds,
  ) {
    final streams = <Stream<List<ScheduleEntry>>>[
      _scheduleQuery(
        firestore
            .collection('schedules')
            .where('teacherId', isEqualTo: teacherId),
      ),
    ];
    for (final chunk in _chunks(classIds)) {
      streams.add(
        _scheduleQuery(
          firestore.collection('schedules').where('classId', whereIn: chunk),
        ),
      );
    }
    return _mergeListStreams(streams, (entry) => entry.id);
  }

  Stream<List<ScheduleOverride>> _teacherOverrideQueries(
    String teacherId,
    Set<String> classIds,
  ) {
    final streams = <Stream<List<ScheduleOverride>>>[
      _overrideQuery(
        firestore
            .collection('schedule_overrides')
            .where('teacherId', isEqualTo: teacherId),
      ),
    ];
    for (final chunk in _chunks(classIds)) {
      streams.add(
        _overrideQuery(
          firestore
              .collection('schedule_overrides')
              .where('classId', whereIn: chunk),
        ),
      );
    }
    return _mergeListStreams(streams, (override) => override.id);
  }

  /// Keep both membership sources in sync. Older class records can contain a
  /// teacher in `teacherIds` while the corresponding user document is missing
  /// `classIds`; querying both prevents those teachers from losing schedules.
  Stream<List<String>> _teacherClassIdsStream(String teacherId) {
    final userClassIds = firestore
        .collection('users')
        .doc(teacherId)
        .safeSnapshots()
        .map((snapshot) => _normaliseIds(snapshot.data()?['classIds']))
        .handleError((_) => <String>[]);
    final assignedClassIds = firestore
        .collection('classes')
        .where(
          Filter.or(
            Filter('teacherId', isEqualTo: teacherId),
            Filter('teacherIds', arrayContains: teacherId),
          ),
        )
        .safeSnapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList())
        .handleError((_) => <String>[]);

    return _mergeListStreams<String>([
      userClassIds,
      assignedClassIds,
    ], (id) => id);
  }

  Stream<List<ScheduleEntry>> _scheduleQuery(
    Query<Map<String, dynamic>> query,
  ) {
    return query.safeSnapshots().map(
      (snapshot) => snapshot.docs.map(ScheduleEntry.fromDoc).toList(),
    );
  }

  Stream<List<ScheduleOverride>> _overrideQuery(
    Query<Map<String, dynamic>> query,
  ) {
    return query.safeSnapshots().map(
      (snapshot) => snapshot.docs.map(ScheduleOverride.fromDoc).toList(),
    );
  }

  List<String> _normaliseIds(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Iterable<List<String>> _chunks(Iterable<String> ids) sync* {
    final values = ids.toList();
    for (var start = 0; start < values.length; start += 30) {
      final end = (start + 30).clamp(0, values.length);
      yield values.sublist(start, end);
    }
  }

  /// Merge owner- and class-based Firestore listeners without duplicating a
  /// schedule that matches both queries.
  Stream<List<T>> _mergeListStreams<T>(
    List<Stream<List<T>>> streams,
    String Function(T value) keyOf,
  ) {
    if (streams.length == 1) return streams.first;

    late StreamController<List<T>> controller;
    final latest = List<List<T>>.filled(streams.length, const []);
    final subscriptions = <StreamSubscription<List<T>>>[];

    void emit() {
      if (controller.isClosed) return;
      final merged = <String, T>{};
      for (final values in latest) {
        for (final value in values) {
          merged[keyOf(value)] = value;
        }
      }
      controller.add(merged.values.toList());
    }

    controller = StreamController<List<T>>.broadcast(
      onListen: () {
        for (var index = 0; index < streams.length; index++) {
          final streamIndex = index;
          subscriptions.add(
            streams[streamIndex].listen(
              (values) {
                latest[streamIndex] = values;
                emit();
              },
              onError: (Object error, StackTrace stackTrace) {
                if (!controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
              },
            ),
          );
        }
      },
      onCancel: () async {
        final active = List<StreamSubscription<List<T>>>.from(subscriptions);
        subscriptions.clear();
        for (final subscription in active) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<List<ScheduleEntry>> studentSchedulesStream(List<String> classIds) {
    if (classIds.isEmpty) return Stream.value([]);
    return firestore
        .collection('schedules')
        .where('classId', whereIn: classIds)
        .safeSnapshots()
        .map((s) => s.docs.map(ScheduleEntry.fromDoc).toList());
  }

  Stream<List<ScheduleOverride>> studentScheduleOverridesStream(
    List<String> classIds,
  ) {
    if (classIds.isEmpty) return Stream.value([]);
    return firestore
        .collection('schedule_overrides')
        .where('classId', whereIn: classIds)
        .safeSnapshots()
        .map((s) => s.docs.map(ScheduleOverride.fromDoc).toList());
  }

  Future<void> createSchedule(ScheduleEntry entry) async {
    final res = await functions
        .httpsCallable('createSchedule')
        .call(entry.toCreatePayload());
    final docId =
        (res.data as Map?)?['id']?.toString() ??
        (res.data as Map?)?['scheduleId']?.toString();
    if (docId != null &&
        docId.isNotEmpty &&
        entry.subject != null &&
        entry.subject!.isNotEmpty) {
      await firestore.collection('schedules').doc(docId).set({
        'subject': entry.subject,
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> patch,
  ) async {
    await functions.httpsCallable('updateSchedule').call({
      'scheduleId': scheduleId,
      ...patch,
    });
    if (patch.containsKey('subject')) {
      await firestore.collection('schedules').doc(scheduleId).set({
        'subject': patch['subject'] ?? '',
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await functions.httpsCallable('deleteSchedule').call({
      'scheduleId': scheduleId,
    });
  }

  Future<void> upsertScheduleOverride({
    required String scheduleId,
    required DateTime date,
    bool? cancelled,
    int? newStartMinute,
    int? newEndMinute,
    String? note,
  }) async {
    final iso =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await functions.httpsCallable('upsertScheduleOverride').call({
      'scheduleId': scheduleId,
      'date': iso,
      if (cancelled != null) 'cancelled': cancelled,
      if (newStartMinute != null) 'newStartMinute': newStartMinute,
      if (newEndMinute != null) 'newEndMinute': newEndMinute,
      if (note != null) 'note': note,
    });
  }
}
