import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/features/session/connectivity_banner.dart';
import 'package:shizuka/services/timer_service.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class BreakScreen extends ConsumerStatefulWidget {
  const BreakScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends ConsumerState<BreakScreen>
    with TickerProviderStateMixin {
  StreamSubscription<int>? _tickSub;

  // 4 drifting petal controllers
  final List<AnimationController> _petalControllers = [];
  final List<Animation<double>> _petalY = [];

  static const _petalXFractions = [0.15, 0.45, 0.70, 0.30];
  static const _petalDelaysMs = [0, 1200, 2400, 3600];
  static const _petalSizes = [36.0, 28.0, 40.0, 24.0];
  static const _petalOpacities = [0.45, 0.35, 0.50, 0.40];
  static const _petalAngles = [0.4, -0.6, 0.9, -0.3];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < 4; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 7000 + i * 400),
      );

      // Animate from -0.15 (above screen) to 1.15 (below screen) as fraction of height
      final yAnim = Tween<double>(begin: -0.15, end: 1.15).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      );

      _petalControllers.add(controller);
      _petalY.add(yAnim);

      Future.delayed(Duration(milliseconds: _petalDelaysMs[i]), () {
        if (mounted) controller.repeat();
      });
    }

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
    for (final c in _petalControllers) {
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

  Future<void> _skipBreak() async {
    if (!_isHost) return;
    final state = ref.read(timerStateProvider(widget.roomId)).valueOrNull;
    if (state == null) return;
    await ref.read(timerServiceProvider).advance(widget.roomId, state);
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

    final phase = timerState?.phase ?? TimerPhase.shortBreak;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remainingMs =
        timerState != null ? timerState.remainingMs(nowMs) : 0;
    final isLongBreak = phase == TimerPhase.longBreak;
    final breakLabel = isLongBreak ? 'Long break' : 'Short break';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ShizukaTokens.background,
        body: WashiBackground(
          showSakura: true,
          child: SafeArea(
            child: ConnectivityBanner(
              roomId: widget.roomId,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Drifting sakura petals
                      ...List.generate(4, (i) {
                        return AnimatedBuilder(
                          animation: _petalY[i],
                          builder: (context, _) {
                            return Positioned(
                              left: _petalXFractions[i] * constraints.maxWidth,
                              top: _petalY[i].value * constraints.maxHeight,
                              child: Opacity(
                                opacity: _petalOpacities[i],
                                child: Transform.rotate(
                                  angle: _petalAngles[i],
                                  child: SakuraPetal(
                                    size: _petalSizes[i],
                                    color: ShizukaTokens.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),

                      // Main content column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Custom back-arrow header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: ShizukaTokens.textSecondary,
                                  onPressed: () =>
                                      context.go('/session/${widget.roomId}'),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // "Break Time" title
                          const Text(
                            'Break Time',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: ShizukaTokens.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // "Short break · 5:00" in Noto Serif JP
                          Text(
                            '$breakLabel · ${_formatRemaining(remainingMs)}',
                            style: GoogleFonts.notoSerifJp(
                              fontSize: 18,
                              color: ShizukaTokens.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Matcha-tinted tip card
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x1F8FAF8F),
                                border: Border.all(
                                  color: const Color(0x408FAF8F),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SUGGESTIONS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: Color(0xFF5C7C5C),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ...[
                                    'Step away from your screen',
                                    'Stretch your shoulders and neck',
                                    'Hydrate · sip some tea',
                                  ].map((tip) => _TipRow(tip: tip)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Skip break plain text button
                          TextButton(
                            onPressed: _skipBreak,
                            child: const Text(
                              'Skip break',
                              style: TextStyle(
                                fontSize: 13,
                                color: ShizukaTokens.textSecondary,
                              ),
                            ),
                          ),

                          const Spacer(),
                        ],
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

class _TipRow extends StatelessWidget {
  const _TipRow({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ShizukaTokens.matcha,
            ),
          ),
          Text(
            tip,
            style: const TextStyle(
              fontSize: 14,
              color: ShizukaTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
