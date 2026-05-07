import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/features/session/connectivity_banner.dart';
import 'package:shizuka/repositories/intention_repository.dart';
import 'package:shizuka/services/timer_service.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  StreamSubscription<int>? _tickSub;

  static const _gracePeriodMs = 60 * 1000;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Per-second tick: refresh remaining-time display + host auto-advance.
    _tickSub =
        Stream.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
      if (mounted) {
        setState(() {});
        _checkAutoAdvance();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Navigate away when phase changes to something the session screen
      // doesn't handle (checkIn / breaks / reflection).
      ref.listenManual(timerStateProvider(widget.roomId), (prev, next) {
        final state = next.valueOrNull;
        if (state == null || !mounted) return;
        switch (state.phase) {
          case TimerPhase.checkIn:
            context.go('/check-in/${widget.roomId}');
          case TimerPhase.shortBreak:
          case TimerPhase.longBreak:
            context.go('/break/${widget.roomId}');
          case TimerPhase.reflection:
            context.go('/reflection/${widget.roomId}');
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

  String _formatRemaining(int remainingMs) {
    final total = remainingMs ~/ 1000;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timerAsync = ref.watch(timerStateProvider(widget.roomId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final intentionsAsync = ref.watch(intentionsProvider(widget.roomId));
    final currentUser = ref.read(authStateChangesProvider).valueOrNull;
    final theme = Theme.of(context);

    final timerState = timerAsync.valueOrNull;
    final room = roomAsync.valueOrNull;
    final isHost = currentUser != null &&
        room != null &&
        currentUser.uid == room.hostUid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Capture before any async gap.
        final router = GoRouter.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave session?'),
            content: const Text(
              'Leaving will end the session for everyone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (leave == true) {
          await ref
              .read(roomRepositoryProvider)
              .setRoomEnded(widget.roomId);
          router.go('/home');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ConnectivityBanner(
            roomId: widget.roomId,
            child: timerAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (_) => _buildBody(
              context,
              theme,
              timerState,
              isHost,
              room?.hostUid ?? '',
              intentionsAsync.valueOrNull ?? {},
              currentUser?.uid ?? '',
              room != null
                  ? room.members.values
                      .map((m) => m.uid)
                      .toList()
                  : [],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    TimerState? state,
    bool isHost,
    String hostUid,
    Map<String, Intention> intentions,
    String myUid,
    List<String> memberUids,
  ) {
    final phase = state?.phase ?? TimerPhase.idle;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remainingMs =
        state != null ? state.remainingMs(nowMs) : 0;
    final sessionStartedMs = state?.startedAtMs ?? nowMs;
    final graceExpired =
        (nowMs - sessionStartedMs) > _gracePeriodMs;
    final myIntention = intentions[myUid];

    return Column(
      children: [
        // ── Top bar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                phase == TimerPhase.idle
                    ? 'Ready'
                    : 'Block ${state?.blockNumber ?? 1}  •  Focus',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isHost && phase == TimerPhase.focus)
                _HostControls(
                  roomId: widget.roomId,
                  state: state!,
                ),
            ],
          ),
        ),

        const Spacer(),

        // ── Breathing animation ──────────────────────────────────────
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(
                opacity: _opacityAnim.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary
                        .withAlpha((255 * 0.18).round()),
                    border: Border.all(
                      color: theme.colorScheme.primary
                          .withAlpha((255 * 0.4).round()),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary
                            .withAlpha((255 * 0.6).round()),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // ── Time remaining ───────────────────────────────────────────
        if (phase.hasCountdown)
          Text(
            _formatRemaining(remainingMs),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        else if (phase == TimerPhase.idle)
          Text(
            isHost ? 'Tap Start to begin' : 'Waiting for host…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

        const Spacer(),

        // ── Intentions list ──────────────────────────────────────────
        if (phase == TimerPhase.focus || phase == TimerPhase.idle)
          _IntentionsList(
            intentions: intentions,
            memberUids: memberUids,
            myUid: myUid,
            graceExpired: graceExpired,
            myIntention: myIntention,
            roomId: widget.roomId,
          ),

        // ── Host start button (idle only) ────────────────────────────
        if (isHost && phase == TimerPhase.idle)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    ref.read(timerServiceProvider).startFocus(widget.roomId),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Focus'),
              ),
            ),
          )
        else
          const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _HostControls extends ConsumerWidget {
  const _HostControls({required this.roomId, required this.state});

  final String roomId;
  final TimerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause / Resume
        IconButton(
          icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
          tooltip: state.isPaused ? 'Resume' : 'Pause',
          onPressed: () {
            final svc = ref.read(timerServiceProvider);
            state.isPaused
                ? svc.resume(roomId, state)
                : svc.pause(roomId);
          },
        ),
        // Skip
        IconButton(
          icon: const Icon(Icons.skip_next),
          tooltip: 'Skip to check-in',
          onPressed: () =>
              ref.read(timerServiceProvider).advance(roomId, state),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _IntentionsList extends ConsumerStatefulWidget {
  const _IntentionsList({
    required this.intentions,
    required this.memberUids,
    required this.myUid,
    required this.graceExpired,
    required this.myIntention,
    required this.roomId,
  });

  final Map<String, Intention> intentions;
  final List<String> memberUids;
  final String myUid;
  final bool graceExpired;
  final Intention? myIntention;
  final String roomId;

  @override
  ConsumerState<_IntentionsList> createState() => _IntentionsListState();
}

class _IntentionsListState extends ConsumerState<_IntentionsList> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(intentionRepositoryProvider).submitIntention(
            roomId: widget.roomId,
            uid: widget.myUid,
            text: text,
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubmitted = widget.myIntention != null;

    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Intentions', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          // My intention input / display
          if (!hasSubmitted && !widget.graceExpired)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 120,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Your intention…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Set'),
                ),
              ],
            )
          else if (!hasSubmitted)
            Text(
              'Intention window closed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          const SizedBox(height: 8),
          // All submitted intentions
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.memberUids.length,
              itemBuilder: (context, i) {
                final uid = widget.memberUids[i];
                final intention = widget.intentions[uid];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        intention != null
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 8,
                        color: intention != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          intention?.text ?? '—',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: intention != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontStyle: intention == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
