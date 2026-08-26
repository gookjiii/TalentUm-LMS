import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/models/schedule.dart';

void main() {
  test('includes the first recurring lesson on its effective-from date', () {
    final schedule = ScheduleEntry(
      id: 'september-math',
      teacherId: 'teacher-1',
      classId: 'externat',
      dayOfWeek: DateTime.tuesday,
      startMinute: 8 * 60,
      endMinute: 9 * 60,
      effectiveFrom: DateTime.utc(2026, 9, 1),
    );

    final items = resolveDay(
      date: DateTime(2026, 9, 1),
      schedules: [schedule],
      overrides: const [],
    );

    expect(items, hasLength(1));
    expect(items.single.startMinute, 8 * 60);
  });

  test('keeps the effective-to date inclusive across a month boundary', () {
    final schedule = ScheduleEntry(
      id: 'august-friday',
      teacherId: 'teacher-1',
      classId: 'externat',
      dayOfWeek: DateTime.friday,
      startMinute: 8 * 60,
      endMinute: 9 * 60,
      effectiveTo: DateTime.utc(2026, 9, 4),
    );

    final items = resolveDay(
      date: DateTime(2026, 9, 4),
      schedules: [schedule],
      overrides: const [],
    );

    expect(items, hasLength(1));
  });
}
