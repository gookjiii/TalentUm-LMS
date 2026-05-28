sealed class ValidationResult {
  const ValidationResult();

  bool get isValid => this is Valid;
  bool get isInvalid => this is Invalid;
}

final class Valid extends ValidationResult {
  const Valid();
}

final class Invalid extends ValidationResult {
  const Invalid(this.message);

  final String message;
}

const valid = Valid();
Invalid invalid(String message) => Invalid(message);
