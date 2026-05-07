import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/services/reflection_service.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  late final Future<ReflectionResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _generate();
  }

  Future<ReflectionResult> _generate() async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    // Wait for room data if not yet loaded.
    final room = await ref
        .read(roomProvider(widget.roomId).future);

    if (user == null || room == null) {
      throw Exception('Session data unavailable.');
    }

    return ref.read(reflectionServiceProvider).generateAndSave(
          uid: user.uid,
          room: room,
        );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: FutureBuilder<ReflectionResult>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const _LoadingView();
              }
              if (snap.hasError) {
                return _ErrorView(
                  error: snap.error.toString(),
                  onSkip: () => context.go('/home'),
                );
              }
              return _ResultView(
                result: snap.data!,
                onDone: () => context.go('/home'),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating your reflection…',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onSkip});

  final String error;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Could not generate reflection',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.replaceFirst('Exception: ', ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onSkip,
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onDone});

  final ReflectionResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Session Complete',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Session summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    icon: Icons.timer_outlined,
                    value: '${result.durationMinutes} min',
                    label: 'Total time',
                  ),
                  _SummaryItem(
                    icon: Icons.local_fire_department_outlined,
                    value: '${result.blockCount}',
                    label: 'Blocks',
                  ),
                  _SummaryItem(
                    icon: Icons.group_outlined,
                    value: '${result.memberCount}',
                    label: 'Members',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Your Reflection',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // Reflection text
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                result.reflectionText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Visible only to you',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
