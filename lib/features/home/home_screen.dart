import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/repositories/profile_repository.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final sessionsAsync = ref.watch(sessionHistoryProvider);

    final initial = profileAsync.value?.email?.isNotEmpty == true
        ? profileAsync.value!.email[0].toUpperCase()
        : '?';

    return Scaffold(
      body: WashiBackground(
        showSakura: true,
        child: Stack(
          children: [
            // Scrollable content
            Positioned.fill(
              child: RefreshIndicator(
                color: ShizukaTokens.primaryDark,
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(sessionHistoryProvider);
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 16,
                    20,
                    120 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    _Header(
                      initial: initial,
                      onAvatarTap: () => context.go('/profile'),
                    ),
                    const SizedBox(height: 24),
                    _StreakCard(profileAsync: profileAsync),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: BrushDivider(),
                    ),
                    const SizedBox(height: 20),
                    _SessionHistorySection(sessionsAsync: sessionsAsync),
                  ],
                ),
              ),
            ),
            // Floating frosted bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _FloatingBar(
                onJoin: () => context.go('/join-room'),
                onCreate: () => context.go('/create-room'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.initial, required this.onAvatarTap});

  final String initial;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SakuraIcon(size: 22),
        const SizedBox(width: 8),
        const Text(
          'Shizuka',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ShizukaTokens.textPrimary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5D5D7), ShizukaTokens.primary],
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ShizukaTokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Streak card ─────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.profileAsync});

  final AsyncValue<UserProfile?> profileAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ShizukaTokens.primaryDark.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: ShizukaTokens.card,
          child: Stack(
            children: [
              // Top-right watermark
              Positioned(
                top: -20,
                right: -20,
                child: Opacity(
                  opacity: 0.12,
                  child: SakuraIcon(
                    size: 110,
                    color: ShizukaTokens.primary,
                  ),
                ),
              ),
              // Bottom-left watermark
              Positioned(
                bottom: -15,
                left: -15,
                child: Opacity(
                  opacity: 0.08,
                  child: SakuraIcon(
                    size: 80,
                    color: ShizukaTokens.primary,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 28),
                child: profileAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: ShizukaTokens.primaryDark,
                    ),
                  ),
                  error: (e, _) => Text(
                    'Error: $e',
                    style: const TextStyle(color: ShizukaTokens.error),
                  ),
                  data: (profile) {
                    final streak = profile?.streak ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '🔥  CURRENT STREAK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: ShizukaTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$streak',
                          style: GoogleFonts.notoSerifJp(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: ShizukaTokens.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          streak == 1 ? '1 day streak' : '$streak day streak',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ShizukaTokens.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Session history ─────────────────────────────────────────────────────────

class _SessionHistorySection extends StatelessWidget {
  const _SessionHistorySection({required this.sessionsAsync});

  final AsyncValue<List<SessionSummary>> sessionsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sessionsAsync.when(
          loading: () => const Row(
            children: [
              Text(
                'Past Sessions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ShizukaTokens.textPrimary,
                ),
              ),
            ],
          ),
          error: (e, _) => Text(
            'Error: $e',
            style: const TextStyle(color: ShizukaTokens.error),
          ),
          data: (sessions) => Row(
            children: [
              const Text(
                'Past Sessions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ShizukaTokens.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${sessions.length} total',
                style: const TextStyle(
                  fontSize: 13,
                  color: ShizukaTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        sessionsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(
                color: ShizukaTokens.primaryDark,
              ),
            ),
          ),
          error: (e, _) => const SizedBox.shrink(),
          data: (sessions) {
            if (sessions.isEmpty) return const _EmptyState();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _SessionTile(session: sessions[i]),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const EnsoCircle(size: 108),
            const SizedBox(height: 20),
            const Text(
              'Your first session awaits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ShizukaTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start a room and invite a friend',
              style: TextStyle(
                fontSize: 13,
                color: ShizukaTokens.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(session.date);
    final duration = session.durationMinutes;
    final members = session.memberCount;

    return Container(
      decoration: BoxDecoration(
        color: ShizukaTokens.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShizukaTokens.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Matcha gradient circle
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB8D4B8), ShizukaTokens.matcha],
              ),
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Focus Session',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ShizukaTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ShizukaTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Duration + members
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$duration min',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ShizukaTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$members ${members == 1 ? 'member' : 'members'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ShizukaTokens.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Floating bottom bar ──────────────────────────────────────────────────────

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({required this.onJoin, required this.onCreate});

  final VoidCallback onJoin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ShizukaTokens.background.withValues(alpha: 0),
                ShizukaTokens.background.withValues(alpha: 0.96),
              ],
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
          child: Row(
            children: [
              Expanded(
                child: ShizukaSecondaryButton(
                  onPressed: onJoin,
                  isFullWidth: true,
                  child: const Text('Join Room'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShizukaPrimaryButton(
                  onPressed: onCreate,
                  isFullWidth: true,
                  child: const Text('New Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
