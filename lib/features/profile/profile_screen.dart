import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/repositories/profile_repository.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final sessionsAsync = ref.watch(sessionHistoryProvider);

    final profile = profileAsync.valueOrNull;
    final sessions = sessionsAsync.valueOrNull ?? [];

    final initial = profile?.email.isNotEmpty == true
        ? profile!.email[0].toUpperCase()
        : '?';
    final email = profile?.email ?? '';
    final streak = profile?.streak ?? 0;
    final sessionCount = sessions.length;
    final totalMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    return Scaffold(
      backgroundColor: ShizukaTokens.background,
      body: WashiBackground(
        showSakura: true,
        child: SafeArea(
          child: Column(
            children: [
              // Back-arrow header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: ShizukaTokens.textSecondary,
                      onPressed: () => context.go('/home'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    // Avatar
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
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
                            style: GoogleFonts.mPlusRounded1c(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: ShizukaTokens.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Email
                    Center(
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ShizukaTokens.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 3 stat cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Sessions',
                            value: '$sessionCount',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Streak',
                            value: '$streak',
                            suffix: 'days',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Minutes',
                            value: '$totalMinutes',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Brush divider
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: BrushDivider(),
                    ),

                    const SizedBox(height: 20),

                    // Recent sessions section
                    const Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ShizukaTokens.textPrimary,
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
                      error: (e, _) => Text(
                        'Error: $e',
                        style: const TextStyle(color: ShizukaTokens.error),
                      ),
                      data: (list) {
                        if (list.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No sessions yet.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ShizukaTokens.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _SessionTile(session: list[i]),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Sign out
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          await ref
                              .read(authRepositoryProvider)
                              .signOut();
                          if (context.mounted) context.go('/');
                        },
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 13,
                            color: ShizukaTokens.error,
                          ),
                        ),
                      ),
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

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShizukaTokens.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.notoSerifJp(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ShizukaTokens.textPrimary,
              height: 1.1,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(height: 1),
            Text(
              suffix!,
              style: const TextStyle(
                fontSize: 11,
                color: ShizukaTokens.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ShizukaTokens.textSecondary,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Session tile ─────────────────────────────────────────────────────────────

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
