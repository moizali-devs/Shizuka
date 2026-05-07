import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/features/session/connectivity_banner.dart';
import 'package:shizuka/repositories/checkin_repository.dart';
import 'package:shizuka/services/timer_service.dart';

class BreakScreen extends ConsumerStatefulWidget {
  const BreakScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends ConsumerState<BreakScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  StreamSubscription<int>? _tickSub;

  @override
  void initState() {
    super.initState();

    // Soft breathing animation — slower and more restful than focus.
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _tickSub =
        Stream.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
      if (mounted) {
        setState(() {});
        _checkAutoAdvance();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(timerStateProvider(widget.roomId), (prev, next) {
        final phase = next.valueOrNull?.phase;
        if (!mounted) return;
        switch (phase) {
          case TimerPhase.focus:
            context.go('/session/${widget.roomId}');
          case TimerPhase.reflection:
            context.go('/reflection/${widget.roomId}');
          case TimerPhase.checkIn:
            context.go('/check-in/${widget.roomId}');
          default:
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _tickSub?.cancel();
    super.dispose();
  }

  bool get _isHost {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    final room = ref.read(roomProvider(widget.roomId)).valueOrNull;
    return user != null && room != null && user.uid == room.hostUid;
  }

  void _checkAutoAdvance() {
    if (!_isHost) return;
    final state = ref.read(timerStateProvider(widget.roomId)).valueOrNull;
    if (state == null || state.isPaused || !state.phase.hasCountdown) return;
    if (state.remainingMs(DateTime.now().millisecondsSinceEpoch) == 0) {
      ref.read(timerServiceProvider).advance(widget.roomId, state);
    }
  }

  String _formatRemaining(int ms) {
    final total = ms ~/ 1000;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timerState =
        ref.watch(timerStateProvider(widget.roomId)).valueOrNull;
    final theme = Theme.of(context);

    final phase = timerState?.phase ?? TimerPhase.shortBreak;
    final blockNumber = timerState?.blockNumber ?? 1;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remainingMs =
        timerState != null ? timerState.remainingMs(nowMs) : 0;
    final isLongBreak = phase == TimerPhase.longBreak;

    final checkInsAsync =
        ref.watch(checkInsProvider((widget.roomId, blockNumber)));
    final checkIns = checkInsAsync.valueOrNull ?? {};

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ConnectivityBanner(
            roomId: widget.roomId,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Text(
                  isLongBreak ? 'Long Break' : 'Short Break',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Breathing circle
                AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, _) {
                    final scale = Tween<double>(begin: 0.8, end: 1.0)
                        .animate(CurvedAnimation(
                          parent: _breathController,
                          curve: Curves.easeInOut,
                        ))
                        .value;
                    final opacity = Tween<double>(begin: 0.4, end: 0.85)
                        .animate(CurvedAnimation(
                          parent: _breathController,
                          curve: Curves.easeInOut,
                        ))
                        .value;
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.secondary
                                .withAlpha((255 * 0.2).round()),
                            border: Border.all(
                              color: theme.colorScheme.secondary
                                  .withAlpha((255 * 0.5).round()),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Countdown
                Text(
                  _formatRemaining(remainingMs),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  isLongBreak
                      ? 'Reflection break'
                      : 'Back to focus soon',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // Check-in responses
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Block $blockNumber recap',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: checkIns.isEmpty
                      ? Center(
                          child: Text(
                            'No check-ins submitted.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : _CheckInList(checkIns: checkIns),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CheckInList extends StatelessWidget {
  const _CheckInList({required this.checkIns});

  final Map<String, CheckIn> checkIns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = checkIns.values.toList();

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final checkIn = entries[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    checkIn.text,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
