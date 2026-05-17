import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  bool _loading = false;

  Future<void> _createRoom() async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final room = await ref
          .read(roomRepositoryProvider)
          .createRoom(user.uid);
      if (mounted) {
        context.go('/lobby/${room.roomId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create room: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WashiBackground(
        showSakura: true,
        child: SafeArea(
          child: Column(
            children: [
              // Custom header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ScreenHeader(
                  title: 'New Session',
                  onBack: () => context.go('/home'),
                ),
              ),
              // Centered content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SakuraIcon(size: 120),
                          const SizedBox(height: 28),
                          const Text(
                            'Create a room and invite\nfriends to focus together',
                            style: TextStyle(
                              fontSize: 15,
                              color: ShizukaTokens.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          ShizukaPrimaryButton(
                            onPressed: _createRoom,
                            isFullWidth: true,
                            isDisabled: _loading,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Create Room'),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'A 6-character room code will be generated',
                            style: TextStyle(
                              fontSize: 12,
                              color: ShizukaTokens.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared header ────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ShizukaTokens.card,
              borderRadius: BorderRadius.circular(ShizukaTokens.radiusSm),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ShizukaTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}
