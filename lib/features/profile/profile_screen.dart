import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/repositories/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final sessionsAsync = ref.watch(sessionHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(profile: profile),
            const SizedBox(height: 24),
            Text('Reflection History', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            sessionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (sessions) => sessions.isEmpty
                  ? _EmptyHistory()
                  : Column(
                      children: sessions
                          .map((s) => _SessionEntry(session: s))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                profile?.email.isNotEmpty == true
                    ? profile!.email[0].toUpperCase()
                    : '?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.email ?? '—',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '${profile?.streak ?? 0} day streak',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No sessions yet.\nComplete a focus session to see your reflections here.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SessionEntry extends StatelessWidget {
  const _SessionEntry({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('MMM d, yyyy  •  h:mm a').format(session.date);
    final hasReflection = session.reflectionText != null &&
        session.reflectionText!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.self_improvement,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(dateStr, style: theme.textTheme.bodyMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _SummaryChips(session: session),
        ),
        // Show a one-line preview when collapsed
        trailing: hasReflection
            ? const Icon(Icons.expand_more)
            : const SizedBox.shrink(),
        children: [
          if (hasReflection) ...[
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  'Private reflection',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.reflectionText!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ] else ...[
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'No reflection recorded for this session.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Wrap(
      spacing: 12,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer_outlined,
              size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text('${session.durationMinutes} min', style: style),
        ]),
        if (session.blockCount > 0)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.local_fire_department_outlined,
                size: 13, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 3),
            Text(
                '${session.blockCount} ${session.blockCount == 1 ? 'block' : 'blocks'}',
                style: style),
          ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.group_outlined,
              size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
              '${session.memberCount} ${session.memberCount == 1 ? 'member' : 'members'}',
              style: style),
        ]),
      ],
    );
  }
}
