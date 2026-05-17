import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/core/router.dart';
import 'package:shizuka/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: ShizukaApp()));
}

class ShizukaApp extends ConsumerWidget {
  const ShizukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Shizuka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: ShizukaTokens.primaryDark,
          onPrimary: Colors.white,
          primaryContainer: ShizukaTokens.primary,
          onPrimaryContainer: ShizukaTokens.textPrimary,
          secondary: ShizukaTokens.matcha,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFD6E8D6),
          onSecondaryContainer: ShizukaTokens.textPrimary,
          error: ShizukaTokens.error,
          onError: Colors.white,
          errorContainer: Color(0xFFF9DEDD),
          onErrorContainer: ShizukaTokens.textPrimary,
          surface: ShizukaTokens.background,
          onSurface: ShizukaTokens.textPrimary,
          surfaceContainerHighest: ShizukaTokens.card,
          onSurfaceVariant: ShizukaTokens.textSecondary,
          outline: ShizukaTokens.primary,
          outlineVariant: Color(0xFFE8E0DB),
          shadow: ShizukaTokens.textPrimary,
          scrim: ShizukaTokens.textPrimary,
          inverseSurface: ShizukaTokens.textPrimary,
          onInverseSurface: ShizukaTokens.background,
          inversePrimary: ShizukaTokens.primary,
        ),
        scaffoldBackgroundColor: ShizukaTokens.background,
        textTheme: GoogleFonts.mPlusRounded1cTextTheme().apply(
          bodyColor: ShizukaTokens.textPrimary,
          displayColor: ShizukaTokens.textPrimary,
        ),
      ),
      routerConfig: router,
    );
  }
}
