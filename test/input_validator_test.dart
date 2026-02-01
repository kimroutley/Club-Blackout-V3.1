import 'package:club_blackout/utils/input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidator Sanitization', () {
    test('sanitizeString should preserve apostrophes', () {
      const input = "O'Connor";
      final result = InputValidator.sanitizeString(input);
      // Current behavior (bug): "OConnor"
      // Desired behavior: "O'Connor"
      expect(result, equals("O'Connor"));
    });

    test('sanitizeString should remove underscores', () {
      const input = 'User_Name';
      final result = InputValidator.sanitizeString(input);
      // Current behavior (bug): "User_Name" (because \w includes _)
      // Desired behavior: "UserName" (because validation rejects _)
      expect(result, equals('UserName'));
    });

    test('validatePlayerName should allow apostrophes', () {
      const input = "O'Connor";
      final result = InputValidator.validatePlayerName(input);
      expect(result.isValid, isTrue);
    });

    test('validatePlayerName should reject underscores', () {
      const input = 'User_Name';
      final result = InputValidator.validatePlayerName(input);
      expect(result.isValid, isFalse);
    });
  });
}
