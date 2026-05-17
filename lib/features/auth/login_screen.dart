import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }
    if (_isRegisterMode && password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isRegisterMode) {
        await auth.register(
          email: email,
          password: password,
        );
      } else {
        await auth.login(
          email: email,
          password: password,
        );
      }
      // Router redirect handles navigation on auth state change
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WashiBackground(
        showSakura: true,
        child: Stack(
          children: [
            // Corner sakura watermarks
            Positioned(
              top: -20,
              right: -30,
              child: Opacity(
                opacity: 0.13,
                child: Transform.rotate(
                  angle: -0.2,
                  child: const SakuraIcon(size: 180),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: -40,
              child: Opacity(
                opacity: 0.08,
                child: Transform.rotate(
                  angle: 0.3,
                  child: const SakuraIcon(size: 150),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand mark
                        const Center(child: SakuraIcon(size: 64)),
                        const SizedBox(height: 14),
                        const Text(
                          'Shizuka',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: ShizukaTokens.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '静か',
                                style: GoogleFonts.notoSerifJp(
                                  fontSize: 13,
                                  color: ShizukaTokens.textSecondary,
                                ),
                              ),
                              const TextSpan(
                                text: ' • Study together, anywhere',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ShizukaTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Email field
                        ShizukaTextInput(
                          label: 'Email',
                          controller: _emailController,
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: ShizukaTokens.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password field
                        ShizukaTextInput(
                          label: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: ShizukaTokens.textSecondary,
                            size: 20,
                          ),
                        ),

                        // Forgot password (sign-in mode only)
                        if (!_isRegisterMode) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ShizukaTokens.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Error banner
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: ShizukaTokens.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  ShizukaTokens.radiusSm),
                              border: Border.all(
                                color:
                                    ShizukaTokens.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: ShizukaTokens.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: ShizukaTokens.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Primary CTA
                        ShizukaPrimaryButton(
                          onPressed: _submit,
                          isFullWidth: true,
                          isDisabled: _isLoading,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRegisterMode ? 'Create Account' : 'Sign In',
                                ),
                        ),
                        const SizedBox(height: 20),

                        // "or" divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: ShizukaTokens.textSecondary
                                    .withValues(alpha: 0.3),
                                thickness: 0.5,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ShizukaTokens.textSecondary
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: ShizukaTokens.textSecondary
                                    .withValues(alpha: 0.3),
                                thickness: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Register / sign-in toggle
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => setState(() {
                                    _isRegisterMode = !_isRegisterMode;
                                    _errorMessage = null;
                                  }),
                          child: Text.rich(
                            _isRegisterMode
                                ? const TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ShizukaTokens.textSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign in',
                                        style: TextStyle(
                                          color: ShizukaTokens.primaryDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )
                                : const TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ShizukaTokens.textSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Register',
                                        style: TextStyle(
                                          color: ShizukaTokens.primaryDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                            textAlign: TextAlign.center,
                          ),
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
    );
  }
}
