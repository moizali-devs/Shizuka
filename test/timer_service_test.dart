import 'package:flutter_test/flutter_test.dart';
import 'package:shizuka/services/timer_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // timerNextPhase
  // ---------------------------------------------------------------------------

  group('timerNextPhase', () {
    test('idle → focus', () {
      expect(timerNextPhase(TimerPhase.idle, 1), TimerPhase.focus);
    });

    test('focus → checkIn', () {
      expect(timerNextPhase(TimerPhase.focus, 1), TimerPhase.checkIn);
    });

    test('checkIn (block 1) → shortBreak', () {
      expect(timerNextPhase(TimerPhase.checkIn, 1), TimerPhase.shortBreak);
    });

    test('checkIn (block 2) → longBreak', () {
      expect(timerNextPhase(TimerPhase.checkIn, 2), TimerPhase.longBreak);
    });

    test('shortBreak → focus', () {
      expect(timerNextPhase(TimerPhase.shortBreak, 1), TimerPhase.focus);
    });

    test('longBreak → reflection', () {
      expect(timerNextPhase(TimerPhase.longBreak, 2), TimerPhase.reflection);
    });

    test('reflection → throws ArgumentError', () {
      expect(
        () => timerNextPhase(TimerPhase.reflection, 2),
        throwsArgumentError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // timerNextBlock
  // ---------------------------------------------------------------------------

  group('timerNextBlock', () {
    test('shortBreak increments block number', () {
      expect(timerNextBlock(TimerPhase.shortBreak, 1), 2);
    });

    test('focus does not change block number', () {
      expect(timerNextBlock(TimerPhase.focus, 1), 1);
    });

    test('checkIn does not change block number', () {
      expect(timerNextBlock(TimerPhase.checkIn, 1), 1);
    });

    test('longBreak does not change block number', () {
      expect(timerNextBlock(TimerPhase.longBreak, 2), 2);
    });

    test('idle does not change block number', () {
      expect(timerNextBlock(TimerPhase.idle, 1), 1);
    });
  });

  // ---------------------------------------------------------------------------
  // isValidTimerTransition
  // ---------------------------------------------------------------------------

  group('isValidTimerTransition - valid transitions', () {
    test('idle → focus is valid', () {
      expect(isValidTimerTransition(TimerPhase.idle, TimerPhase.focus), isTrue);
    });

    test('focus → checkIn is valid', () {
      expect(isValidTimerTransition(TimerPhase.focus, TimerPhase.checkIn), isTrue);
    });

    test('checkIn → shortBreak is valid', () {
      expect(isValidTimerTransition(TimerPhase.checkIn, TimerPhase.shortBreak), isTrue);
    });

    test('checkIn → longBreak is valid', () {
      expect(isValidTimerTransition(TimerPhase.checkIn, TimerPhase.longBreak), isTrue);
    });

    test('shortBreak → focus is valid', () {
      expect(isValidTimerTransition(TimerPhase.shortBreak, TimerPhase.focus), isTrue);
    });

    test('longBreak → reflection is valid', () {
      expect(isValidTimerTransition(TimerPhase.longBreak, TimerPhase.reflection), isTrue);
    });
  });

  group('isValidTimerTransition - invalid transitions', () {
    test('idle → checkIn is invalid', () {
      expect(isValidTimerTransition(TimerPhase.idle, TimerPhase.checkIn), isFalse);
    });

    test('focus → shortBreak is invalid', () {
      expect(isValidTimerTransition(TimerPhase.focus, TimerPhase.shortBreak), isFalse);
    });

    test('checkIn → focus is invalid', () {
      expect(isValidTimerTransition(TimerPhase.checkIn, TimerPhase.focus), isFalse);
    });

    test('shortBreak → checkIn is invalid', () {
      expect(isValidTimerTransition(TimerPhase.shortBreak, TimerPhase.checkIn), isFalse);
    });

    test('reflection → anything is invalid', () {
      for (final phase in TimerPhase.values) {
        expect(isValidTimerTransition(TimerPhase.reflection, phase), isFalse);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Full phase progression sequence
  // ---------------------------------------------------------------------------

  group('full phase progression', () {
    test('block 1 → check-in → short-break → block 2 → check-in → long-break → reflection', () {
      // Start: idle, block 1
      var phase = TimerPhase.idle;
      var block = 1;

      // idle → focus (block 1)
      phase = timerNextPhase(phase, block);
      block = timerNextBlock(TimerPhase.idle, block);
      expect(phase, TimerPhase.focus);
      expect(block, 1);

      // focus → checkIn (block 1)
      phase = timerNextPhase(phase, block);
      block = timerNextBlock(TimerPhase.focus, block);
      expect(phase, TimerPhase.checkIn);
      expect(block, 1);

      // checkIn (block 1) → shortBreak
      phase = timerNextPhase(phase, block);
      block = timerNextBlock(TimerPhase.checkIn, block);
      expect(phase, TimerPhase.shortBreak);
      expect(block, 1);

      // shortBreak → focus (block 2)
      phase = timerNextPhase(phase, block);
      block = timerNextBlock(TimerPhase.shortBreak, block);
      expect(phase, TimerPhase.focus);
      expect(block, 2);

      // focus → checkIn (block 2)
      phase = timerNextPhase(phase, block);
      block = timerNextBlock(TimerPhase.focus, block);
      expect(phase, TimerPhase.checkIn);
      expect(block, 2);

      // checkIn (block 2) → longBreak
      phase = timerNextPhase(phase, block);
      block = timerNextBlock(TimerPhase.checkIn, block);
      expect(phase, TimerPhase.longBreak);
      expect(block, 2);

      // longBreak → reflection
      phase = timerNextPhase(phase, block);
      block = timerNextBlock(TimerPhase.longBreak, block);
      expect(phase, TimerPhase.reflection);
      expect(block, 2);
    });
  });
}
