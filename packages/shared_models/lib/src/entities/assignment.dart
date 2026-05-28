class Assignment {
  const Assignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdBy,
  });

  final String id;
  final String classId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String createdBy;
}
