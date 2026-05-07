import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/features/session/connectivity_banner.dart';
import 'package:shizuka/services/timer_service.dart';

/// Seconds after check-in phase starts before the host auto-advances.
const _kCheckInTimeoutSeconds = 90;

/// Seconds the responses are shown before the host auto-advances to break.
const _kRevealCountdownSeconds = 8;

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
  // Once all members have submitted or timeout fires, we enter reveal mode.
  bool _resolved = false;
  int _revealSecondsLeft = _kRevealCountdownSeconds;

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
      // Navigate to break when timer phase changes away from checkIn.
      ref.listenManual(timerStateProvider(widget.roomId), (prev, next) {
        final phase = next.valueOrNull?.phase;
        if (!mounted) return;
        if (phase == TimerPhase.shortBreak || phase == TimerPhase.longBreak) {
          context.go('/break/${widget.roomId}');
        }
        if (phase == TimerPhase.focus || phase == TimerPhase.idle) {
          // Navigated back (shouldn't normally happen, but guard it).
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

    final timerState = ref.read(timerStateProvider(widget.roomId)).valueOrNull;
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
    final text = _textController.text.trim();
    if (text.isEmpty) return;

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
    final isHost = _isHost;

    final checkInsAsync =
        ref.watch(checkInsProvider((widget.roomId, blockNumber)));
    final checkIns = checkInsAsync.valueOrNull ?? {};
    final submittedCount = checkIns.length;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ConnectivityBanner(
            roomId: widget.roomId,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _resolved
                ? _RevealView(
                    checkIns: checkIns,
                    totalMembers: totalMembers,
                    isHost: isHost,
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

// ---------------------------------------------------------------------------

class _CheckInForm extends StatelessWidget {
  const _CheckInForm({
    required this.blockNumber,
    required this.submitted,
    required this.submitting,
    required this.submittedCount,
    required this.totalMembers,
    required this.controller,
    required this.onSubmit,
    required this.timeoutSecondsLeft,
  });

  final int blockNumber;
  final bool submitted;
  final bool submitting;
  final int submittedCount;
  final int totalMembers;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final int timeoutSecondsLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Block $blockNumber  •  Check-In',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'What did you get done?',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        if (!submitted) ...[
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 300,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              hintText: 'Describe what you accomplished…',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ),
        ] else
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: theme.colorScheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Spacer(),
        // Progress row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$submittedCount / $totalMembers submitted',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$timeoutSecondsLeft s',
              style: theme.textTheme.bodySmall?.copyWith(
                color: timeoutSecondsLeft <= 15
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: totalMembers > 0 ? submittedCount / totalMembers : 0,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

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
    final theme = Theme.of(context);
    final entries = checkIns.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What everyone got done',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${checkIns.length} of $totalMembers submitted',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final checkIn = entries[i].value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    checkIn.text as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (isHost)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              child: Text('Continue to Break ($revealSecondsLeft s)'),
            ),
          )
        else
          Center(
            child: Text(
              'Break starting in $revealSecondsLeft s…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
