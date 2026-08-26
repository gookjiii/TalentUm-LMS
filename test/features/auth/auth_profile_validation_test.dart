import 'package:flutter_test/flutter_test.dart';
import 'package:school_world/src/features/auth/domain/auth_profile_validation.dart';

void main() {
  group('normalizePhoneNumber', () {
    test('removes formatting and keeps an international number', () {
      expect(normalizePhoneNumber(' +84 (90) 123-4567 '), '+84901234567');
    });

    test('converts Vietnamese local and 00-prefixed numbers to E.164', () {
      expect(normalizePhoneNumber('090 123 4567'), '+84901234567');
      expect(normalizePhoneNumber('0084901234567'), '+84901234567');
    });

    test('accepts only valid E.164 phone numbers', () {
      expect(isValidInternationalPhoneNumber('+84901234567'), isTrue);
      expect(isValidInternationalPhoneNumber('0901234567'), isFalse);
      expect(isValidInternationalPhoneNumber('+8401'), isFalse);
    });
  });

  group('profile details validation', () {
    test('normalizes a display name without changing its words', () {
      expect(normalizeDisplayName('  Nguyen   Van  An '), 'Nguyen Van An');
      expect(normalizeDisplayName('   '), isEmpty);
    });

    test('normalizes an optional contact email and validates it', () {
      expect(
        normalizeOptionalEmail(' Parent@Example.COM '),
        'parent@example.com',
      );
      expect(normalizeOptionalEmail('  '), isNull);
      expect(isValidEmailAddress('parent@example.com'), isTrue);
      expect(isValidEmailAddress('not-an-email'), isFalse);
    });
  });
}
