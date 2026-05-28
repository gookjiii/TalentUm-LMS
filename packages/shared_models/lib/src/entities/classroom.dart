class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.studentIds,
    required this.parentIds,
  });

  final String id;
  final String name;
  final String teacherId;
  final List<String> studentIds;
  final List<String> parentIds;
}
