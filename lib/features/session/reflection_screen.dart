import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/services/reflection_service.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

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
    final room = await ref.read(roomProvider(widget.roomId).future);

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
        backgroundColor: ShizukaTokens.background,
        body: WashiBackground(
          showSakura: true,
          child: SafeArea(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: ShizukaTokens.primaryDark),
          const SizedBox(height: 24),
          Text(
            'Generating your reflection…',
            style: GoogleFonts.notoSerifJp(
              fontSize: 15,
              color: ShizukaTokens.textSecondary,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: ShizukaTokens.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Could not generate reflection',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: ShizukaTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.replaceFirst('Exception: ', ''),
              style: const TextStyle(
                fontSize: 13,
                color: ShizukaTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            ShizukaPrimaryButton(
              onPressed: onSkip,
              isFullWidth: true,
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.result, required this.onDone});

  final ReflectionResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final streak = profile?.streak ?? 0;
    final timeLabel = DateFormat('HH:mm').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back-arrow header
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: ShizukaTokens.textSecondary,
              onPressed: onDone,
            ),
          ),

          const SizedBox(height: 8),

          // Title
          const Text(
            'Session Complete ✨',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: ShizukaTokens.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Here\'s your AI reflection',
            style: TextStyle(
              fontSize: 13,
              color: ShizukaTokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Journal-entry card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFCF9), Color(0xFFFBF6EE)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: ShizukaTokens.cardShadow,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: ShizukaTokens.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                  // Card content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REFLECTION · $timeLabel',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: ShizukaTokens.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.reflectionText,
                            style: GoogleFonts.notoSerifJp(
                              fontSize: 15,
                              height: 1.75,
                              color: ShizukaTokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User's intention
          if (result.intentionText != null) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12),
                  children: [
                    const TextSpan(
                      text: 'Your intention · ',
                      style: TextStyle(color: ShizukaTokens.textSecondary),
                    ),
                    TextSpan(
                      text: result.intentionText,
                      style: const TextStyle(
                        color: ShizukaTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Streak badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x2E8FAF8F),
              border: Border.all(color: const Color(0x528FAF8F)),
              borderRadius: BorderRadius.circular(ShizukaTokens.radiusPill),
            ),
            child: Text(
              '🔥 +1 Streak · now $streak days',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F6B4F),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Back to Home button
          ShizukaPrimaryButton(
            onPressed: onDone,
            isFullWidth: true,
            child: const Text('Back to Home'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
