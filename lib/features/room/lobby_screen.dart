import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/repositories/room_repository.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _intentionController = TextEditingController();
  bool _submitting = false;
  bool _starting = false;
  bool _intentionSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // When host goes offline, mark room as ended.
      ref.listenManual(hostOnlineProvider(widget.roomId), (prev, next) {
        if (prev?.valueOrNull == true && next.valueOrNull == false) {
          ref.read(roomRepositoryProvider).setRoomEnded(widget.roomId);
        }
      });

      // Navigate all members to session when host starts.
      ref.listenManual(roomProvider(widget.roomId), (prev, next) {
        final room = next.valueOrNull;
        if (room != null && room.status == 'active' && mounted) {
          context.go('/session/${widget.roomId}');
        }
      });
    });
  }

  @override
  void dispose() {
    _intentionController.dispose();
    super.dispose();
  }

  Future<void> _submitIntention() async {
    final text = _intentionController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(intentionRepositoryProvider).submitIntention(
            roomId: widget.roomId,
            uid: user.uid,
            text: text,
          );
      if (mounted) setState(() => _intentionSubmitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit intention: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _startSession() async {
    setState(() => _starting = true);
    try {
      await ref.read(roomRepositoryProvider).startSession(widget.roomId);
      // Navigation triggered by roomProvider listener above.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start session: $e')),
        );
        setState(() => _starting = false);
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.roomId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room code copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final intentionsAsync = ref.watch(intentionsProvider(widget.roomId));
    final currentUser = ref.read(authStateChangesProvider).valueOrNull;

    return Scaffold(
      body: WashiBackground(
        showSakura: true,
        child: SafeArea(
          child: roomAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ShizukaTokens.primaryDark),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: ShizukaTokens.error)),
            ),
            data: (room) {
              if (room == null) {
                return const Center(child: Text('Room not found.'));
              }
              if (room.status == 'ended') {
                return _EndedBanner(onHome: () => context.go('/home'));
              }

              final isHost = currentUser?.uid == room.hostUid;
              final intentions = intentionsAsync.valueOrNull ?? {};
              final myUid = currentUser?.uid ?? '';
              final myIntentionSubmitted =
                  _intentionSubmitted || intentions.containsKey(myUid);
              final hostSubmitted = intentions.containsKey(room.hostUid);
              final members = room.members.values.toList()
                ..sort((a, b) {
                  if (a.uid == room.hostUid) return -1;
                  if (b.uid == room.hostUid) return 1;
                  return a.character.compareTo(b.character);
                });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: ShizukaTokens.card,
                              borderRadius: BorderRadius.circular(
                                  ShizukaTokens.radiusSm),
                              boxShadow: ShizukaTokens.cardShadow,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: ShizukaTokens.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Lobby',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ShizukaTokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable body + pinned host button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Room code card
                          _RoomCodeCard(
                            roomId: widget.roomId,
                            onCopy: _copyCode,
                          ),
                          const SizedBox(height: 16),
                          const BrushDivider(),
                          const SizedBox(height: 16),
                          // Intention section
                          _IntentionSection(
                            controller: _intentionController,
                            submitted: myIntentionSubmitted,
                            submitting: _submitting,
                            onSubmit: _submitIntention,
                          ),
                          const SizedBox(height: 20),
                          // Members header
                          Text(
                            'Members (${members.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ShizukaTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Members list
                          Expanded(
                            child: ListView.separated(
                              itemCount: members.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _MemberRow(
                                member: members[i],
                                hostUid: room.hostUid,
                                submitted:
                                    intentions.containsKey(members[i].uid),
                              ),
                            ),
                          ),
                          // Host start button
                          if (isHost) ...[
                            const SizedBox(height: 16),
                            ShizukaPrimaryButton(
                              onPressed: _startSession,
                              isFullWidth: true,
                              isDisabled: !hostSubmitted || _starting,
                              child: _starting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      hostSubmitted
                                          ? 'Start Session'
                                          : 'Submit your intention to start',
                                    ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Room code card ───────────────────────────────────────────────────────────

class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.roomId, required this.onCopy});

  final String roomId;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ShizukaTokens.radiusMd),
        boxShadow: ShizukaTokens.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ShizukaTokens.radiusMd),
        child: ColoredBox(
          color: ShizukaTokens.card,
          child: Stack(
            children: [
              // Watermark
              Positioned(
                right: -12,
                top: -12,
                child: Opacity(
                  opacity: 0.10,
                  child: SakuraIcon(
                    size: 80,
                    color: ShizukaTokens.primary,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Room Code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: ShizukaTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roomId,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 6,
                              color: ShizukaTokens.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Share with others to join',
                            style: TextStyle(
                              fontSize: 12,
                              color: ShizukaTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onCopy,
                      icon: const Icon(
                        Icons.copy_outlined,
                        color: ShizukaTokens.primaryDark,
                        size: 20,
                      ),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Intention section ────────────────────────────────────────────────────────

class _IntentionSection extends StatelessWidget {
  const _IntentionSection({
    required this.controller,
    required this.submitted,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitted;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF8FAF8F).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Color(0xFF4F6B4F),
            ),
            SizedBox(width: 8),
            Text(
              'Intention set',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4F6B4F),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ShizukaTextInput(
            label: 'What will you focus on today?',
            controller: controller,
            maxLength: 120,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 10),
        ShizukaSecondaryButton(
          onPressed: onSubmit,
          isDisabled: submitting,
          child: submitting
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
    );
  }
}

// ─── Member row ───────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.hostUid,
    required this.submitted,
  });

  final RoomMember member;
  final String hostUid;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    final isHost = member.uid == hostUid;
    final initial =
        member.character.isNotEmpty ? member.character[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ShizukaTokens.card,
        borderRadius: BorderRadius.circular(ShizukaTokens.radiusMd),
        boxShadow: ShizukaTokens.cardShadow,
      ),
      child: Row(
        children: [
          // Blush avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ShizukaTokens.primary.withValues(alpha: 0.35),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ShizukaTokens.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              member.character,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: ShizukaTokens.textPrimary,
              ),
            ),
          ),
          // Checkmark
          if (submitted)
            const Icon(Icons.check_circle, color: ShizukaTokens.matcha, size: 20)
          else
            Icon(
              Icons.radio_button_unchecked,
              color: ShizukaTokens.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          // Host pill
          if (isHost) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ShizukaTokens.primaryDark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Host',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ShizukaTokens.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Ended banner ─────────────────────────────────────────────────────────────

class _EndedBanner extends StatelessWidget {
  const _EndedBanner({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EnsoCircle(size: 96),
            const SizedBox(height: 20),
            const Text(
              'This room has ended.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ShizukaTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The host has left the session.',
              style: TextStyle(
                fontSize: 13,
                color: ShizukaTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ShizukaPrimaryButton(
              onPressed: onHome,
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
