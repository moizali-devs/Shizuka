import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shizuka/core/providers.dart';

/// Wraps [child] with an animated offline banner shown only during an active
/// session. When connectivity is restored, room and timer providers are
/// invalidated so they resubscribe and pick up the latest server state.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({
    super.key,
    required this.roomId,
    required this.child,
  });

  final String roomId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected =
        ref.watch(connectionStateProvider).valueOrNull ?? true;

    // Invalidate providers on reconnect so clients resync without manual
    // navigation.
    ref.listen(connectionStateProvider, (prev, next) {
      final wasOffline = prev?.valueOrNull == false;
      final nowOnline = next.valueOrNull == true;
      if (wasOffline && nowOnline) {
        ref.invalidate(roomProvider(roomId));
        ref.invalidate(timerStateProvider(roomId));
        ref.invalidate(intentionsProvider(roomId));
      }
    });

    return Column(
      children: [
        _OfflineBanner(visible: !isConnected),
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: visible
          ? Container(
              width: double.infinity,
              color: theme.colorScheme.errorContainer,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'No internet connection — reconnecting…',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
