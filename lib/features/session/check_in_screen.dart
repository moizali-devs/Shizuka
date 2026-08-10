import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/features/session/connectivity_banner.dart';
import 'package:shizuka/services/timer_service.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

const _kCheckInTimeoutSeconds = 90;
const _kRevealCountdownSeconds = 8;

const _kMoodEmojis = ['😫', '😕', '😐', '🙂', '✨'];
const _kMoodLabels = ['Drained', 'Distracted', 'Okay', 'Good', 'Flowing'];

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _textController = TextEditingController();
  StreamSubscription<int>? _tickSub;

  bool _submitting = false;
  bool _submitted = false;
  bool _resolved = false;
  int _revealSecondsLeft = _kRevealCountdownSeconds;
  int? _selectedMood; // 1–5

  @override
  void initState() {
    super.initState();

    _tickSub =
        Stream.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
      if (!mounted) return;
      setState(() {});
      _checkResolution();
      if (_resolved) _tickReveal();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(timerStateProvider(widget.roomId), (prev, next) {
        final phase = next.valueOrNull?.phase;
        if (!mounted) return;
        if (phase == TimerPhase.shortBreak || phase == TimerPhase.longBreak) {
          context.go('/break/${widget.roomId}');
        }
        if (phase == TimerPhase.focus || phase == TimerPhase.idle) {
          context.go('/session/${widget.roomId}');
        }
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _tickSub?.cancel();
    super.dispose();
  }

  bool get _isHost {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    final room = ref.read(roomProvider(widget.roomId)).valueOrNull;
    return user != null && room != null && user.uid == room.hostUid;
  }

  void _checkResolution() {
    if (_resolved) return;
    final timerState =
        ref.read(timerStateProvider(widget.roomId)).valueOrNull;
    if (timerState == null) return;
    final room = ref.read(roomProvider(widget.roomId)).valueOrNull;
    if (room == null) return;

    final blockNumber = timerState.blockNumber;
    final checkIns = ref
        .read(checkInsProvider((widget.roomId, blockNumber)))
        .valueOrNull;

    final allSubmitted =
        checkIns != null && checkIns.length >= room.members.length;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final timedOut =
        (nowMs - timerState.startedAtMs) >= _kCheckInTimeoutSeconds * 1000;

    if (allSubmitted || timedOut) {
      setState(() {
        _resolved = true;
        _revealSecondsLeft = _kRevealCountdownSeconds;
      });
    }
  }

  void _tickReveal() {
    if (!_isHost) return;
    if (_revealSecondsLeft > 0) {
      setState(() => _revealSecondsLeft--);
    } else {
      _advanceToBreak();
    }
  }

  Future<void> _advanceToBreak() async {
    final timerState =
        ref.read(timerStateProvider(widget.roomId)).valueOrNull;
    if (timerState == null) return;
    try {
      await ref.read(timerServiceProvider).advance(widget.roomId, timerState);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_selectedMood == null) return;

    final moodLabel = _kMoodLabels[_selectedMood! - 1];
    final note = _textController.text.trim();
    final text = note.isNotEmpty ? '$moodLabel: $note' : moodLabel;

    final user = ref.read(authStateChangesProvider).valueOrNull;
    final timerState =
        ref.read(timerStateProvider(widget.roomId)).valueOrNull;
    if (user == null || timerState == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(checkInRepositoryProvider).submitCheckIn(
            roomId: widget.roomId,
            uid: user.uid,
            blockNumber: timerState.blockNumber,
            text: text,
          );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerAsync = ref.watch(timerStateProvider(widget.roomId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));

    final timerState = timerAsync.valueOrNull;
    final room = roomAsync.valueOrNull;
    final blockNumber = timerState?.blockNumber ?? 1;
    final totalMembers = room?.members.length ?? 0;

    final checkInsAsync =
        ref.watch(checkInsProvider((widget.roomId, blockNumber)));
    final checkIns = checkInsAsync.valueOrNull ?? {};
    final submittedCount = checkIns.length;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: WashiBackground(
          showSakura: true,
          child: SafeArea(
            child: ConnectivityBanner(
              roomId: widget.roomId,
              child: _resolved
                  ? _RevealView(
                      checkIns: checkIns,
                      totalMembers: totalMembers,
                      isHost: _isHost,
                      revealSecondsLeft: _revealSecondsLeft,
                      onContinue: _advanceToBreak,
                    )
                  : _CheckInForm(
                      blockNumber: blockNumber,
                      submitted: _submitted,
                      submitting: _submitting,
                      submittedCount: submittedCount,
                      totalMembers: totalMembers,
                      controller: _textController,
                      selectedMood: _selectedMood,
                      onMoodSelected: (m) =>
                          setState(() => _selectedMood = m),
                      onSubmit: _submit,
                      timeoutSecondsLeft: timerState != null
                          ? (_kCheckInTimeoutSeconds -
                                  (DateTime.now().millisecondsSinceEpoch -
                                          timerState.startedAtMs) ~/
                                      1000)
                              .clamp(0, _kCheckInTimeoutSeconds)
                          : _kCheckInTimeoutSeconds,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Check-in form ────────────────────────────────────────────────────────────

class _CheckInForm extends StatelessWidget {
  const _CheckInForm({
    required this.blockNumber,
    required this.submitted,
    required this.submitting,
    required this.submittedCount,
    required this.totalMembers,
    required this.controller,
    required this.selectedMood,
    required this.onMoodSelected,
    required this.onSubmit,
    required this.timeoutSecondsLeft,
  });

  final int blockNumber;
  final bool submitted;
  final bool submitting;
  final int submittedCount;
  final int totalMembers;
  final TextEditingController controller;
  final int? selectedMood;
  final ValueChanged<int> onMoodSelected;
  final VoidCallback onSubmit;
  final int timeoutSecondsLeft;

  @override
  Widget build(BuildContext context) {
    final moodLabel =
        selectedMood != null ? _kMoodLabels[selectedMood! - 1] : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Zen bowl illustration
          SizedBox(
            width: 120,
            height: 80,
            child: CustomPaint(painter: _ZenBowlPainter()),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            "How's it going?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ShizukaTokens.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Block $blockNumber complete · Take a moment',
            style: const TextStyle(
              fontSize: 13,
              color: ShizukaTokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Mood buttons
          if (!submitted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < 5; i++)
                  _MoodButton(
                    emoji: _kMoodEmojis[i],
                    selected: selectedMood == i + 1,
                    onTap: () => onMoodSelected(i + 1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                moodLabel,
                key: ValueKey(moodLabel),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ShizukaTokens.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Note textarea
            _NoteTextArea(controller: controller),
            const SizedBox(height: 24),

            // Submit button
            ShizukaPrimaryButton(
              onPressed: onSubmit,
              isFullWidth: true,
              isDisabled: selectedMood == null || submitting,
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Continue to Break →'),
            ),
          ] else ...[
            // Submitted confirmation
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8FAF8F).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: Color(0xFF4F6B4F)),
                  SizedBox(width: 8),
                  Text(
                    'Check-in submitted',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4F6B4F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for others…',
              style: TextStyle(
                  fontSize: 13, color: ShizukaTokens.textSecondary),
            ),
          ],

          const SizedBox(height: 32),

          // Progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$submittedCount / $totalMembers submitted',
                style: const TextStyle(
                    fontSize: 12, color: ShizukaTokens.textSecondary),
              ),
              Text(
                '${timeoutSecondsLeft}s',
                style: TextStyle(
                  fontSize: 12,
                  color: timeoutSecondsLeft <= 15
                      ? ShizukaTokens.error
                      : ShizukaTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalMembers > 0 ? submittedCount / totalMembers : 0,
              backgroundColor:
                  ShizukaTokens.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(ShizukaTokens.matcha),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zen bowl painter ─────────────────────────────────────────────────────────

class _ZenBowlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = ShizukaTokens.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer rim line
    canvas.drawLine(
      Offset(w * 0.08, h * 0.28),
      Offset(w * 0.92, h * 0.28),
      stroke,
    );

    // Bowl body: U-curve from left rim to right rim
    final bowl = Path()
      ..moveTo(w * 0.08, h * 0.28)
      ..cubicTo(
        w * 0.04, h * 0.52,
        w * 0.16, h * 0.95,
        w * 0.50, h * 0.98,
      )
      ..cubicTo(
        w * 0.84, h * 0.95,
        w * 0.96, h * 0.52,
        w * 0.92, h * 0.28,
      );
    canvas.drawPath(bowl, stroke);

    // Inner rim shadow (subtle)
    final rim = Paint()
      ..color = ShizukaTokens.textPrimary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(w * 0.14, h * 0.35),
      Offset(w * 0.86, h * 0.35),
      rim,
    );
  }

  @override
  bool shouldRepaint(_ZenBowlPainter old) => false;
}

// ─── Mood button ──────────────────────────────────────────────────────────────

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? ShizukaTokens.primaryDark.withValues(alpha: 0.08)
              : const Color(0xFFFFFCF9),
          border: Border.all(
            color: selected
                ? ShizukaTokens.primaryDark
                : ShizukaTokens.primary.withValues(alpha: 0.4),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ShizukaTokens.primaryDark.withValues(alpha: 0.10),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

// ─── Note text area ───────────────────────────────────────────────────────────

class _NoteTextArea extends StatefulWidget {
  const _NoteTextArea({required this.controller});

  final TextEditingController controller;

  @override
  State<_NoteTextArea> createState() => _NoteTextAreaState();
}

class _NoteTextAreaState extends State<_NoteTextArea> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: ShizukaTokens.primaryDark.withValues(alpha: 0.12),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: 3,
        maxLength: 300,
        style: const TextStyle(
            fontSize: 14, color: ShizukaTokens.textPrimary),
        decoration: InputDecoration(
          hintText: 'Optional note…',
          hintStyle: const TextStyle(
              color: ShizukaTokens.textSecondary, fontSize: 14),
          filled: true,
          fillColor: ShizukaTokens.background,
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: ShizukaTokens.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: ShizukaTokens.primaryDark, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Reveal view ─────────────────────────────────────────────────────────────

class _RevealView extends StatelessWidget {
  const _RevealView({
    required this.checkIns,
    required this.totalMembers,
    required this.isHost,
    required this.revealSecondsLeft,
    required this.onContinue,
  });

  final Map<String, dynamic> checkIns;
  final int totalMembers;
  final bool isHost;
  final int revealSecondsLeft;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final entries = checkIns.entries.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What everyone got done',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ShizukaTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${checkIns.length} of $totalMembers submitted',
            style: const TextStyle(
                fontSize: 13, color: ShizukaTokens.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final checkIn = entries[i].value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ShizukaTokens.card,
                    borderRadius:
                        BorderRadius.circular(ShizukaTokens.radiusMd),
                    boxShadow: ShizukaTokens.cardShadow,
                  ),
                  child: Text(
                    checkIn.text as String,
                    style: const TextStyle(
                        fontSize: 14, color: ShizukaTokens.textPrimary),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (isHost)
            ShizukaPrimaryButton(
              onPressed: onContinue,
              isFullWidth: true,
              child: Text('Continue to Break ($revealSecondsLeft s)'),
            )
          else
            Center(
              child: Text(
                'Break starting in $revealSecondsLeft s…',
                style: const TextStyle(
                    fontSize: 13, color: ShizukaTokens.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
