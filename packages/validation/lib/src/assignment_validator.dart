import 'validation_result.dart';

class AssignmentValidator {
  static const maxTitleLength = 120;
  static const maxDescriptionLength = 5000;

  static ValidationResult validateTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return invalid('Assignment title cannot be empty');
    if (trimmed.length > maxTitleLength) return invalid('Assignment title too long');
    return valid;
  }

  static ValidationResult validateDescription(String value) {
    if (value.length > maxDescriptionLength) {
      return invalid('Assignment description too long');
    }
    return valid;
  }
}
