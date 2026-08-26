/// Normalizes a phone number entered with common formatting characters into
/// the E.164 format expected by Firebase Phone Auth.
String normalizePhoneNumber(String input, {String defaultCountryCode = '+84'}) {
  var value = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
  if (value.startsWith('00')) value = '+${value.substring(2)}';
  if (value.startsWith('0')) value = '$defaultCountryCode${value.substring(1)}';
  return value;
}

bool isValidInternationalPhoneNumber(String phoneNumber) {
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber);
}

String normalizeDisplayName(String input) {
  return input.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String? normalizeOptionalEmail(String input) {
  final email = input.trim().toLowerCase();
  return email.isEmpty ? null : email;
}

bool isValidEmailAddress(String email) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}
