import 'package:firebase_database/firebase_database.dart';

// ---------------------------------------------------------------------------
// Phase + durations
// ---------------------------------------------------------------------------

enum TimerPhase { idle, focus, checkIn, shortBreak, longBreak, reflection }

extension TimerPhaseX on TimerPhase {
  static const _durationSeconds = {
    TimerPhase.focus: 45 * 60,
    TimerPhase.shortBreak: 10 * 60,
    TimerPhase.longBreak: 15 * 60,
    // idle / checkIn / reflection: no countdown
  };

  int get durationSeconds => _durationSeconds[this] ?? 0;
  bool get hasCountdown => _durationSeconds.containsKey(this);
}

// ---------------------------------------------------------------------------
// TimerState model
// ---------------------------------------------------------------------------

class TimerState {
  const TimerState({
    required this.phase,
    required this.blockNumber,
    required this.startedAtMs,
    required this.isPaused,
    this.pausedAtMs,
  });

  final TimerPhase phase;
  final int blockNumber; // 1 or 2
  final int startedAtMs; // epoch ms (server time)
  final bool isPaused;
  final int? pausedAtMs; // epoch ms when paused (null if not paused)

  /// Remaining milliseconds in the current phase at [nowMs].
  /// Returns 0 for phases without a countdown (checkIn, idle, reflection).
  int remainingMs(int nowMs) {
    final durMs = phase.durationSeconds * 1000;
    if (durMs == 0) return 0;
    final elapsedMs = isPaused
        ? (pausedAtMs ?? nowMs) - startedAtMs
        : nowMs - startedAtMs;
    return (durMs - elapsedMs).clamp(0, durMs).toInt();
  }

  factory TimerState.fromMap(Map<String, dynamic> map) {
    final phaseName = map['phase'] as String? ?? 'idle';
    return TimerState(
      phase: TimerPhase.values.firstWhere(
        (p) => p.name == phaseName,
        orElse: () => TimerPhase.idle,
      ),
      blockNumber: (map['blockNumber'] as num?)?.toInt() ?? 1,
      startedAtMs: (map['startedAt'] as num?)?.toInt() ?? 0,
      isPaused: map['isPaused'] as bool? ?? false,
      pausedAtMs: (map['pausedAt'] as num?)?.toInt(),
    );
  }
}

// ---------------------------------------------------------------------------
// State machine helpers (static — easily unit-testable)
// ---------------------------------------------------------------------------

/// Returns the next [TimerPhase] given the current phase and block number.
/// Throws [ArgumentError] for invalid transitions.
TimerPhase timerNextPhase(TimerPhase current, int blockNumber) {
  switch (current) {
    case TimerPhase.idle:
      return TimerPhase.focus;
    case TimerPhase.focus:
      return TimerPhase.checkIn;
    case TimerPhase.checkIn:
      return blockNumber == 1 ? TimerPhase.shortBreak : TimerPhase.longBreak;
    case TimerPhase.shortBreak:
      return TimerPhase.focus;
    case TimerPhase.longBreak:
      return TimerPhase.reflection;
    case TimerPhase.reflection:
      throw ArgumentError('No transition from TimerPhase.reflection');
  }
}

/// Returns the block number after the transition from [current].
int timerNextBlock(TimerPhase current, int blockNumber) =>
    current == TimerPhase.shortBreak ? blockNumber + 1 : blockNumber;

/// Returns true when transitioning from [from] to [to] is valid,
/// regardless of block number (checkIn permits both short and long break).
bool isValidTimerTransition(TimerPhase from, TimerPhase to) {
  switch (from) {
    case TimerPhase.idle:
      return to == TimerPhase.focus;
    case TimerPhase.focus:
      return to == TimerPhase.checkIn;
    case TimerPhase.checkIn:
      return to == TimerPhase.shortBreak || to == TimerPhase.longBreak;
    case TimerPhase.shortBreak:
      return to == TimerPhase.focus;
    case TimerPhase.longBreak:
      return to == TimerPhase.reflection;
    case TimerPhase.reflection:
      return false;
  }
}

// ---------------------------------------------------------------------------
// TimerService
// ---------------------------------------------------------------------------

class TimerService {
  TimerService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  DatabaseReference _timerRef(String roomId) =>
      _db.ref('rooms/$roomId/timer');

  // --- Write operations (host only) ----------------------------------------

  /// Starts the first focus block. Writes idle → focus to RTDB.
  Future<void> startFocus(String roomId) {
    return _timerRef(roomId).set({
      'phase': TimerPhase.focus.name,
      'blockNumber': 1,
      'startedAt': ServerValue.timestamp,
      'isPaused': false,
      'pausedAt': null,
    });
  }

  /// Advances to the next phase given the [current] state.
  Future<void> advance(String roomId, TimerState current) {
    if (current.phase == TimerPhase.reflection) {
      throw StateError('Cannot advance past reflection');
    }
    final next = timerNextPhase(current.phase, current.blockNumber);
    final nextBlock = timerNextBlock(current.phase, current.blockNumber);
    return _timerRef(roomId).set({
      'phase': next.name,
      'blockNumber': nextBlock,
      'startedAt': ServerValue.timestamp,
      'isPaused': false,
      'pausedAt': null,
    });
  }

  /// Pauses the current phase. Records [ServerValue.timestamp] as pausedAt.
  Future<void> pause(String roomId) {
    return _timerRef(roomId).update({
      'isPaused': true,
      'pausedAt': ServerValue.timestamp,
    });
  }

  /// Resumes a paused phase. Adjusts startedAt so remaining time is preserved.
  Future<void> resume(String roomId, TimerState current) {
    if (!current.isPaused || current.pausedAtMs == null) return Future.value();
    // Elapsed before pause (ms). Uses client time for adjustedStartedAt —
    // tiny drift is acceptable.
    final elapsedMs = current.pausedAtMs! - current.startedAtMs;
    final adjustedStartedAt =
        DateTime.now().millisecondsSinceEpoch - elapsedMs;
    return _timerRef(roomId).update({
      'startedAt': adjustedStartedAt,
      'isPaused': false,
      'pausedAt': null,
    });
  }

  // --- Read operations (all clients) ---------------------------------------

  /// Real-time stream of timer state from RTDB. Emits `null` when no timer
  /// has been written yet (i.e., the room is in the idle pre-start state).
  Stream<TimerState?> watchTimer(String roomId) {
    return _timerRef(roomId).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return null;
      return TimerState.fromMap(Map<String, dynamic>.from(raw as Map));
    });
  }
}
