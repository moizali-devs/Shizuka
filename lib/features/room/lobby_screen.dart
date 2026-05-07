import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/repositories/room_repository.dart';

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
      appBar: AppBar(
        title: const Text('Lobby'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) {
            return const Center(child: Text('Room not found.'));
          }
          if (room.status == 'ended') {
            return const Center(
              child: _EndedBanner(),
            );
          }

          final isHost = currentUser?.uid == room.hostUid;
          final intentions = intentionsAsync.valueOrNull ?? {};
          final myUid = currentUser?.uid ?? '';
          final myIntentionSubmitted =
              _intentionSubmitted || intentions.containsKey(myUid);
          final hostSubmitted = intentions.containsKey(room.hostUid);
          final members = room.members.values.toList()
            ..sort((a, b) {
              // Host first
              if (a.uid == room.hostUid) return -1;
              if (b.uid == room.hostUid) return 1;
              return a.character.compareTo(b.character);
            });

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoomCodeCard(roomId: widget.roomId, onCopy: _copyCode),
                const SizedBox(height: 24),
                _IntentionInput(
                  controller: _intentionController,
                  submitted: myIntentionSubmitted,
                  submitting: _submitting,
                  onSubmit: _submitIntention,
                ),
                const SizedBox(height: 24),
                Text(
                  'Members (${members.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _MemberTile(
                      member: members[i],
                      hostUid: room.hostUid,
                      submitted: intentions.containsKey(members[i].uid),
                    ),
                  ),
                ),
                if (isHost) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: hostSubmitted && !_starting
                          ? _startSession
                          : null,
                      icon: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        hostSubmitted
                            ? 'Start Session'
                            : 'Submit your intention to start',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.roomId, required this.onCopy});

  final String roomId;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room Code',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roomId,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Share with others to join',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy code',
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentionInput extends StatelessWidget {
  const _IntentionInput({
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
    final theme = Theme.of(context);

    if (submitted) {
      return Card(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.text.isEmpty
                      ? 'Intention submitted'
                      : controller.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 1,
            maxLength: 120,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Your intention for this session',
              hintText: 'e.g. Finish chapter 3 of my book',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: submitting ? null : onSubmit,
          child: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Set'),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.hostUid,
    required this.submitted,
  });

  final RoomMember member;
  final String hostUid;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHost = member.uid == hostUid;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          member.character[0],
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
      title: Text(member.character),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (submitted)
            Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
          else
            Icon(Icons.radio_button_unchecked,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
          if (isHost) ...[
            const SizedBox(width: 8),
            Chip(
              label: const Text('Host'),
              labelStyle: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              backgroundColor: theme.colorScheme.primaryContainer,
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}

class _EndedBanner extends StatelessWidget {
  const _EndedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'This room has ended.',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
