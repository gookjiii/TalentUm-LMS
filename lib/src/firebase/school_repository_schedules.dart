import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/schedule.dart';
import 'safe_firestore.dart';

mixin SchoolRepositorySchedules {
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;

  Stream<List<ScheduleEntry>> teacherSchedulesStream(String teacherId) {
    return firestore
        .collection('schedules')
        .where('teacherId', isEqualTo: teacherId)
        .safeSnapshots()
        .map((s) => s.docs.map(ScheduleEntry.fromDoc).toList());
  }

  Stream<List<ScheduleOverride>> teacherScheduleOverridesStream(
    String teacherId,
  ) {
    return firestore
        .collection('schedule_overrides')
        .where('teacherId', isEqualTo: teacherId)
        .safeSnapshots()
        .map((s) => s.docs.map(ScheduleOverride.fromDoc).toList());
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
    await functions
        .httpsCallable('createSchedule')
        .call(entry.toCreatePayload());
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> patch,
  ) async {
    await functions.httpsCallable('updateSchedule').call({
      'scheduleId': scheduleId,
      ...patch,
    });
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
