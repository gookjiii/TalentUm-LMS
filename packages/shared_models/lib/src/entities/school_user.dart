enum UserRole { teacher, student, parent, admin, leadTeacher }

class SchoolUser {
  const SchoolUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.classIds,
  });

  final String id;
  final String displayName;
  final String email;
  final UserRole role;
  final List<String> classIds;
}
