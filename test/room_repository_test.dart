import 'package:flutter_test/flutter_test.dart';
import 'package:shizuka/repositories/room_repository.dart';

void main() {
  group('generateRoomCode', () {
    test('generated code is exactly 6 characters', () {
      for (var i = 0; i < 100; i++) {
        expect(generateRoomCode().length, 6);
      }
    });

    test('generated code only contains [A-Z0-9] characters', () {
      final validChars = RegExp(r'^[A-Z0-9]+$');
      for (var i = 0; i < 100; i++) {
        final code = generateRoomCode();
        expect(validChars.hasMatch(code), isTrue,
            reason: 'Code "$code" contains invalid characters');
      }
    });

    test('kRoomCodeChars contains only uppercase letters and digits', () {
      final validChars = RegExp(r'^[A-Z0-9]+$');
      expect(validChars.hasMatch(kRoomCodeChars), isTrue);
    });

    test('kRoomCodeChars has no duplicates', () {
      final chars = kRoomCodeChars.split('');
      expect(chars.length, chars.toSet().length);
    });
  });
}
