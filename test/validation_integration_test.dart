import 'package:flutter_test/flutter_test.dart';
import 'package:sw_validation/validation.dart';

void main() {
  test('message validation package is available to app', () {
    expect(MessageValidator.validateText('Hello class').isValid, isTrue);
  });
}
