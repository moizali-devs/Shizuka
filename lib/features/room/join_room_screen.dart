import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(
          () => _errorMessage = 'Please enter a 6-character room code.');
      return;
    }

    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final room = await ref
          .read(roomRepositoryProvider)
          .joinRoom(code, user.uid);
      if (mounted) {
        context.go('/lobby/${room.roomId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = e.toString().replaceFirst('Exception: ', ''));
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
                  title: 'Join a Room',
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
                          const SizedBox(height: 8),
                          // Code input
                          ShizukaTextInput(
                            label: 'Room Code',
                            hintText: 'XXXXXX',
                            controller: _codeController,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]')),
                              _UpperCaseFormatter(),
                            ],
                            onSubmitted: (_) => _joinRoom(),
                            textStyle: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                              color: ShizukaTokens.textPrimary,
                            ),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                          ),
                          // Error message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ShizukaTokens.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 28),
                          ShizukaPrimaryButton(
                            onPressed: _joinRoom,
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
                                : const Text('Join'),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Ask the host for their 6-character room code',
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

// ─── Input formatter (preserved from original) ───────────────────────────────

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
