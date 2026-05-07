import 'dart:math';

class StreakService {
  /// Number of full days missed between [lastActiveDate] and [today].
  /// Same-day or consecutive-day → 0. Two days gap → 1. Etc.
  int computeDecrement(DateTime lastActiveDate, DateTime today) {
    final last = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
    final now = DateTime(today.year, today.month, today.day);
    final diff = now.difference(last).inDays;
    return max(0, diff - 1);
  }

  /// Returns the streak after applying the decay for missed days.
  int applyDecrement(int currentStreak, DateTime lastActiveDate, DateTime today) {
    return max(0, currentStreak - computeDecrement(lastActiveDate, today));
  }

  /// Returns the new streak after a completed session.
  /// Increments by 1 unless a session was already recorded today.
  int applySessionComplete(
    int currentStreak,
    DateTime? lastActiveDate,
    DateTime today,
  ) {
    if (lastActiveDate != null) {
      final last = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
      final now = DateTime(today.year, today.month, today.day);
      if (last == now) return currentStreak;
    }
    return currentStreak + 1;
  }
}
