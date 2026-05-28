import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Recurring (or one-off when [dayOfWeek] is null) schedule entry.
class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.dayOfWeek,
    required this.startMinute,
    required this.endMinute,
    this.room,
    this.color,
    this.effectiveFrom,
    this.effectiveTo,
    this.oneOffDate,
  });

  final String id;
  final String teacherId;
  final String classId;

  /// 1=Mon … 7=Sun (ISO). Null for one-off entries.
  final int? dayOfWeek;
  final int startMinute;
  final int endMinute;
  final String? room;
  final String? color;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  /// For one-off entries (dayOfWeek == null) the specific date.
  final DateTime? oneOffDate;

  bool get isRecurring => dayOfWeek != null;

  factory ScheduleEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return ScheduleEntry(
      id: doc.id,
      teacherId: d['teacherId']?.toString() ?? '',
      classId: d['classId']?.toString() ?? '',
      dayOfWeek: (d['dayOfWeek'] as num?)?.toInt(),
      startMinute: (d['startMinute'] as num?)?.toInt() ?? 0,
      endMinute: (d['endMinute'] as num?)?.toInt() ?? 60,
      room: d['room']?.toString(),
      color: d['color']?.toString(),
      effectiveFrom: (d['effectiveFrom'] as Timestamp?)?.toDate(),
      effectiveTo: (d['effectiveTo'] as Timestamp?)?.toDate(),
      oneOffDate: (d['oneOffDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
    'classId': classId,
    if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    'startMinute': startMinute,
    'endMinute': endMinute,
    if (room != null && room!.isNotEmpty) 'room': room,
    if (color != null && color!.isNotEmpty) 'color': color,
    if (effectiveFrom != null)
      'effectiveFrom': DateFormat('yyyy-MM-dd').format(effectiveFrom!),
    if (effectiveTo != null)
      'effectiveTo': DateFormat('yyyy-MM-dd').format(effectiveTo!),
    if (oneOffDate != null)
      'oneOffDate': DateFormat('yyyy-MM-dd').format(oneOffDate!),
  };
}

/// Per-date override of a recurring schedule entry.
class ScheduleOverride {
  ScheduleOverride({
    required this.id,
    required this.scheduleId,
    required this.date,
    required this.cancelled,
    this.newStartMinute,
    this.newEndMinute,
    this.note,
  });

  final String id;
  final String scheduleId;
  final DateTime date; // local Y-M-D
  final bool cancelled;
  final int? newStartMinute;
  final int? newEndMinute;
  final String? note;

  factory ScheduleOverride.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawDate = d['date']?.toString() ?? '';
    DateTime parsed;
    try {
      parsed = DateTime.parse(rawDate);
    } catch (_) {
      parsed = DateTime.now();
    }
    return ScheduleOverride(
      id: doc.id,
      scheduleId: d['scheduleId']?.toString() ?? '',
      date: DateTime(parsed.year, parsed.month, parsed.day),
      cancelled: d['cancelled'] == true,
      newStartMinute: (d['newStartMinute'] as num?)?.toInt(),
      newEndMinute: (d['newEndMinute'] as num?)?.toInt(),
      note: d['note']?.toString(),
    );
  }
}

/// Merged "what runs on a specific date" record.
class ResolvedScheduleItem {
  ResolvedScheduleItem({
    required this.scheduleId,
    required this.classId,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    this.room,
    this.note,
    this.color,
    this.cancelled = false,
  });

  final String scheduleId;
  final String classId;
  final DateTime date;
  final int startMinute;
  final int endMinute;
  final String? room;
  final String? note;
  final String? color;
  final bool cancelled;

  Duration get duration =>
      Duration(minutes: (endMinute - startMinute).clamp(0, 24 * 60));

  DateTime get start => DateTime(
    date.year,
    date.month,
    date.day,
    startMinute ~/ 60,
    startMinute % 60,
  );

  DateTime get end => DateTime(
    date.year,
    date.month,
    date.day,
    endMinute ~/ 60,
    endMinute % 60,
  );
}

/// Compute the resolved items for a given [date] (local) from recurring
/// schedules + overrides. Pure function — easy to unit test.
List<ResolvedScheduleItem> resolveDay({
  required DateTime date,
  required List<ScheduleEntry> schedules,
  required List<ScheduleOverride> overrides,
}) {
  final dayOnly = DateTime(date.year, date.month, date.day);
  final iso = dayOnly.weekday; // 1..7
  final overridesByScheduleId = <String, ScheduleOverride>{};
  for (final o in overrides) {
    if (_sameDay(o.date, dayOnly)) overridesByScheduleId[o.scheduleId] = o;
  }

  final out = <ResolvedScheduleItem>[];
  for (final s in schedules) {
    final isOneOff = s.dayOfWeek == null && s.oneOffDate != null;
    if (isOneOff) {
      if (!_sameDay(s.oneOffDate!, dayOnly)) continue;
    } else {
      if (s.dayOfWeek != iso) continue;
      if (s.effectiveFrom != null && dayOnly.isBefore(s.effectiveFrom!)) {
        continue;
      }
      if (s.effectiveTo != null && dayOnly.isAfter(s.effectiveTo!)) continue;
    }
    final ov = overridesByScheduleId[s.id];
    out.add(
      ResolvedScheduleItem(
        scheduleId: s.id,
        classId: s.classId,
        date: dayOnly,
        startMinute: ov?.newStartMinute ?? s.startMinute,
        endMinute: ov?.newEndMinute ?? s.endMinute,
        room: s.room,
        note: ov?.note,
        color: s.color,
        cancelled: ov?.cancelled ?? false,
      ),
    );
  }
  out.sort((a, b) => a.startMinute.compareTo(b.startMinute));
  return out;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Optional helper for UI tinting.
Color colorFromHex(String? hex, Color fallback) {
  if (hex == null) return fallback;
  final s = hex.replaceAll('#', '');
  if (s.length != 6 && s.length != 8) return fallback;
  final v = int.tryParse(s.length == 6 ? 'FF$s' : s, radix: 16);
  return v == null ? fallback : Color(v);
}
