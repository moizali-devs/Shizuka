import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/features/session/connectivity_banner.dart';
import 'package:shizuka/repositories/intention_repository.dart';
import 'package:shizuka/repositories/room_repository.dart';
import 'package:shizuka/services/timer_service.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with TickerProviderStateMixin {
  // One controller per ring for correct staggered phase
  late final List<AnimationController> _ringControllers;
  late final List<Animation<double>> _ringScales;

  StreamSubscription<int>? _tickSub;

  static const _gracePeriodMs = 60 * 1000;

  // Ring spec: [diameter, opacity, isSolid]
  static const _rings = [
    (40.0, 1.00, true),
    (100.0, 0.50, false),
    (160.0, 0.30, false),
    (220.0, 0.15, false),
    (280.0, 0.08, false),
  ];

  @override
  void initState() {
    super.initState();

    // 5 controllers, each 5 s, started with 150 ms staggered delay.
    _ringControllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      ),
    );

    // Core ring: 0.92 → 1.0; outer rings: 0.96 → 1.04.
    _ringScales = [
      Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ringControllers[0], curve: Curves.easeInOut),
      ),
      ...List.generate(
        4,
        (i) => Tween<double>(begin: 0.96, end: 1.04).animate(
          CurvedAnimation(
              parent: _ringControllers[i + 1], curve: Curves.easeInOut),
        ),
      ),
    ];

    for (var i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _ringControllers[i].repeat(reverse: true);
      });
    }

    // Per-second tick: refresh display + host auto-advance.
    _tickSub =
        Stream.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
      if (mounted) {
        setState(() {});
        _checkAutoAdvance();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    for (final c in _ringControllers) {
      c.dispose();
    }
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

    final timerState = timerAsync.valueOrNull;
    final room = roomAsync.valueOrNull;
    final isHost = currentUser != null &&
        room != null &&
        currentUser.uid == room.hostUid;
    final intentions = intentionsAsync.valueOrNull ?? {};
    final myUid = currentUser?.uid ?? '';
    final members = room?.members ?? {};
    final memberUids = members.values.map((m) => m.uid).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
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
          await ref.read(roomRepositoryProvider).setRoomEnded(widget.roomId);
          router.go('/home');
        }
      },
      child: Scaffold(
        body: WashiBackground(
          showSakura: true,
          child: SafeArea(
            child: ConnectivityBanner(
              roomId: widget.roomId,
              child: timerAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: ShizukaTokens.primaryDark),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: ShizukaTokens.error)),
                ),
                data: (_) {
                  final phase = timerState?.phase ?? TimerPhase.idle;
                  final nowMs = DateTime.now().millisecondsSinceEpoch;
                  final remainingMs =
                      timerState != null ? timerState.remainingMs(nowMs) : 0;
                  final sessionStartedMs =
                      timerState?.startedAtMs ?? nowMs;
                  final graceExpired =
                      (nowMs - sessionStartedMs) > _gracePeriodMs;
                  final myIntention = intentions[myUid];

                  return Stack(
                    children: [
                      // ── Main column ────────────────────────────────
                      Column(
                        children: [
                          // Top bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                            child: Row(
                              children: [
                                Text(
                                  phase == TimerPhase.idle
                                      ? 'Ready'
                                      : 'Block ${timerState?.blockNumber ?? 1}  ·  Focus',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: ShizukaTokens.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                if (isHost && phase == TimerPhase.focus)
                                  _HostControls(
                                    roomId: widget.roomId,
                                    state: timerState!,
                                  ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // ── Breathing ripple ───────────────────────
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outermost first (behind)
                                for (var i = 4; i >= 0; i--)
                                  _RippleRing(
                                    scale: _ringScales[i],
                                    diameter: _rings[i].$1,
                                    opacity: _rings[i].$2,
                                    solid: _rings[i].$3,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Timer ─────────────────────────────────
                          if (phase.hasCountdown)
                            Text(
                              _formatRemaining(remainingMs),
                              style: GoogleFonts.notoSerifJp(
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                color: ShizukaTokens.textPrimary,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            )
                          else
                            Text(
                              phase == TimerPhase.idle
                                  ? (isHost
                                      ? 'Tap Start to begin'
                                      : 'Waiting for host…')
                                  : '',
                              style: const TextStyle(
                                fontSize: 16,
                                color: ShizukaTokens.textSecondary,
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Sub-label
                          if (phase == TimerPhase.focus)
                            const Text(
                              'Stay focused ✦',
                              style: TextStyle(
                                fontSize: 13,
                                color: ShizukaTokens.textSecondary,
                              ),
                            ),

                          const Spacer(),

                          // ── Intentions ─────────────────────────────
                          if (phase == TimerPhase.focus ||
                              phase == TimerPhase.idle)
                            _IntentionsList(
                              intentions: intentions,
                              memberUids: memberUids,
                              members: members,
                              myUid: myUid,
                              graceExpired: graceExpired,
                              myIntention: myIntention,
                              roomId: widget.roomId,
                            ),

                          // ── Host start button (idle) ───────────────
                          if (isHost && phase == TimerPhase.idle)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 24),
                              child: ShizukaPrimaryButton(
                                onPressed: () => ref
                                    .read(timerServiceProvider)
                                    .startFocus(widget.roomId),
                                isFullWidth: true,
                                child: const Text('Start Focus'),
                              ),
                            )
                          else
                            const SizedBox(height: 72), // space for pill
                        ],
                      ),

                      // ── Floating presence pill ─────────────────────
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _PresencePill(
                            memberUids: memberUids,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ripple ring ──────────────────────────────────────────────────────────────

class _RippleRing extends StatelessWidget {
  const _RippleRing({
    required this.scale,
    required this.diameter,
    required this.opacity,
    required this.solid,
  });

  final Animation<double> scale;
  final double diameter;
  final double opacity;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scale,
      builder: (_, __) => Transform.scale(
        scale: scale.value,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: solid ? ShizukaTokens.primary : Colors.transparent,
              border: solid
                  ? null
                  : Border.all(color: ShizukaTokens.primary, width: 1.5),
              boxShadow: solid
                  ? [
                      BoxShadow(
                        color: ShizukaTokens.primary.withValues(alpha: 0.45),
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Host controls ────────────────────────────────────────────────────────────

class _HostControls extends ConsumerWidget {
  const _HostControls({required this.roomId, required this.state});

  final String roomId;
  final TimerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: state.isPaused ? Icons.play_arrow : Icons.pause,
          tooltip: state.isPaused ? 'Resume' : 'Pause',
          onTap: () {
            final svc = ref.read(timerServiceProvider);
            state.isPaused ? svc.resume(roomId, state) : svc.pause(roomId);
          },
        ),
        const SizedBox(width: 8),
        _ControlButton(
          icon: Icons.skip_next,
          tooltip: 'Skip to check-in',
          onTap: () =>
              ref.read(timerServiceProvider).advance(roomId, state),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFFCF9).withValues(alpha: 0.7),
            boxShadow: ShizukaTokens.cardShadow,
          ),
          child: Icon(icon, size: 18, color: ShizukaTokens.textPrimary),
        ),
      ),
    );
  }
}

// ─── Intentions list ──────────────────────────────────────────────────────────

class _IntentionsList extends ConsumerStatefulWidget {
  const _IntentionsList({
    required this.intentions,
    required this.memberUids,
    required this.members,
    required this.myUid,
    required this.graceExpired,
    required this.myIntention,
    required this.roomId,
  });

  final Map<String, Intention> intentions;
  final List<String> memberUids;
  final Map<String, RoomMember> members;
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
    final hasSubmitted = widget.myIntention != null;

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INTENTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: ShizukaTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          // My intention input or grace-expired notice
          if (!hasSubmitted && !widget.graceExpired)
            Row(
              children: [
                Expanded(
                  child: ShizukaTextInput(
                    label: 'Your intention…',
                    controller: _controller,
                    maxLength: 120,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 10),
                ShizukaSecondaryButton(
                  onPressed: _submit,
                  isDisabled: _submitting,
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ShizukaTokens.primaryDark,
                          ),
                        )
                      : const Text('Set'),
                ),
              ],
            )
          else if (!hasSubmitted)
            const Text(
              'Intention window closed',
              style: TextStyle(fontSize: 13, color: ShizukaTokens.error),
            ),
          if (!hasSubmitted) const SizedBox(height: 10),
          // All submitted intentions
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.memberUids.length,
              itemBuilder: (_, i) {
                final uid = widget.memberUids[i];
                final intention = widget.intentions[uid];
                final isMe = uid == widget.myUid;
                final name = isMe
                    ? 'You'
                    : (widget.members[uid]?.character ?? 'Member');

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: intention != null
                              ? ShizukaTokens.primary
                              : ShizukaTokens.textSecondary
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$name  ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: intention != null
                              ? ShizukaTokens.textPrimary
                              : ShizukaTokens.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          intention?.text ?? '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: intention != null
                                ? ShizukaTokens.textPrimary
                                : ShizukaTokens.textSecondary,
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

// ─── Presence pill ────────────────────────────────────────────────────────────

class _PresencePill extends StatelessWidget {
  const _PresencePill({required this.memberUids});

  final List<String> memberUids;

  @override
  Widget build(BuildContext context) {
    final count = memberUids.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF9).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            boxShadow: ShizukaTokens.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Presence dots
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ShizukaTokens.matcha,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                '$count of $count present',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ShizukaTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
