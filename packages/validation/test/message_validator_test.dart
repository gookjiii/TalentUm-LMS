import 'package:sw_validation/validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageValidator', () {
    test('rejects blank messages', () {
      expect(MessageValidator.validateText('   ').isInvalid, isTrue);
    });

    test('rejects overly long messages', () {
      final result = MessageValidator.validateText('a' * 2001);
      expect(result.isInvalid, isTrue);
    });

    test('accepts valid text', () {
      expect(MessageValidator.validateText('Hello').isValid, isTrue);
    });
  });
}
