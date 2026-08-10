import 'package:flutter_test/flutter_test.dart';
import 'package:shizuka/services/streak_service.dart';

void main() {
  late StreakService service;

  setUp(() => service = StreakService());

  group('StreakService.computeDecrement', () {
    test('same-day → 0 decrement', () {
      final day = DateTime(2024, 6, 10);
      expect(service.computeDecrement(day, day), 0);
    });

    test('one missed day → 0 decrement (consecutive days)', () {
      final last = DateTime(2024, 6, 9);
      final today = DateTime(2024, 6, 10);
      expect(service.computeDecrement(last, today), 0);
    });

    test('two days ago → 1 decrement', () {
      final last = DateTime(2024, 6, 8);
      final today = DateTime(2024, 6, 10);
      expect(service.computeDecrement(last, today), 1);
    });

    test('five days ago → 4 decrements', () {
      final last = DateTime(2024, 6, 5);
      final today = DateTime(2024, 6, 10);
      expect(service.computeDecrement(last, today), 4);
    });
  });

  group('StreakService.applyDecrement', () {
    test('floor at zero, large gap on small streak', () {
      final last = DateTime(2024, 6, 1);
      final today = DateTime(2024, 6, 10);
      // 8 missed days, streak 3 → 0
      expect(service.applyDecrement(3, last, today), 0);
    });

    test('streak 5, one missed day → still 5', () {
      final last = DateTime(2024, 6, 9);
      final today = DateTime(2024, 6, 10);
      expect(service.applyDecrement(5, last, today), 5);
    });

    test('streak 5, two days ago → 4', () {
      final last = DateTime(2024, 6, 8);
      final today = DateTime(2024, 6, 10);
      expect(service.applyDecrement(5, last, today), 4);
    });
  });

  group('StreakService.applySessionComplete', () {
    test('same-day session → streak unchanged', () {
      final today = DateTime(2024, 6, 10);
      expect(service.applySessionComplete(7, today, today), 7);
    });

    test('first session ever (null lastActiveDate) → increments', () {
      final today = DateTime(2024, 6, 10);
      expect(service.applySessionComplete(0, null, today), 1);
    });

    test('new day session → increments streak', () {
      final last = DateTime(2024, 6, 9);
      final today = DateTime(2024, 6, 10);
      expect(service.applySessionComplete(5, last, today), 6);
    });

    test('post-session increment after decrement restores correct value', () {
      // streak was 3, missed 1 day (decrement 0), then session → 4
      final last = DateTime(2024, 6, 9);
      final today = DateTime(2024, 6, 10);
      final afterDecrement = service.applyDecrement(3, last, today);
      final afterSession = service.applySessionComplete(afterDecrement, last, today);
      expect(afterSession, 4);
    });
  });
}
