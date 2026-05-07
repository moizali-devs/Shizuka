import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/repositories/profile_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final sessionsAsync = ref.watch(sessionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shizuka'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(sessionHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakCard(profileAsync: profileAsync),
            const SizedBox(height: 24),
            _SessionHistorySection(sessionsAsync: sessionsAsync),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: () => context.go('/join-room'),
            icon: const Icon(Icons.login),
            label: const Text('Join Room'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => context.go('/create-room'),
            icon: const Icon(Icons.add),
            label: const Text('New Session'),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.profileAsync});

  final AsyncValue<UserProfile?> profileAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (profile) {
            final streak = profile?.streak ?? 0;
            return Column(
              children: [
                Text(
                  '🔥',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  '$streak',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  streak == 1 ? '1 day streak' : '$streak day streak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SessionHistorySection extends StatelessWidget {
  const _SessionHistorySection({required this.sessionsAsync});

  final AsyncValue<List<SessionSummary>> sessionsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Past Sessions', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No sessions yet.\nStart your first focus session!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _SessionTile(session: sessions[i]),
            );
          },
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(session.date);
    final duration = session.durationMinutes;
    final members = session.memberCount;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.timer_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(dateStr),
        subtitle: Text(
          '$duration min • $members ${members == 1 ? 'member' : 'members'}',
        ),
      ),
    );
  }
}
