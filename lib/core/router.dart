import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shizuka/core/providers.dart';
import 'package:shizuka/features/auth/login_screen.dart';
import 'package:shizuka/features/home/home_screen.dart';
import 'package:shizuka/features/profile/profile_screen.dart';
import 'package:shizuka/features/room/create_room_screen.dart';
import 'package:shizuka/features/room/join_room_screen.dart';
import 'package:shizuka/features/room/lobby_screen.dart';
import 'package:shizuka/features/session/break_screen.dart';
import 'package:shizuka/features/session/check_in_screen.dart';
import 'package:shizuka/features/session/reflection_screen.dart';
import 'package:shizuka/features/session/session_screen.dart';
import 'package:shizuka/features/splash/splash_screen.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<User?> stream) {
    _sub = stream.listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  User? _user;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  User? get currentUser => _user;

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final notifier = _AuthRefreshNotifier(authRepo.authStateChanges);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Splash handles its own navigation
      if (loc == '/splash') return null;

      // Still determining auth state — go to splash
      if (notifier.isLoading) return '/splash';

      final isLoggedIn = notifier.currentUser != null;

      if (!isLoggedIn && loc != '/login') return '/login';
      if (isLoggedIn && loc == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-room',
        name: 'create_room',
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: '/join-room',
        name: 'join_room',
        builder: (context, state) => const JoinRoomScreen(),
      ),
      GoRoute(
        path: '/lobby/:roomId',
        name: 'lobby',
        builder: (context, state) => LobbyScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/session/:roomId',
        name: 'session',
        builder: (context, state) => SessionScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/check-in/:roomId',
        name: 'check_in',
        builder: (context, state) => CheckInScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/break/:roomId',
        name: 'break_screen',
        builder: (context, state) => BreakScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/reflection/:roomId',
        name: 'reflection',
        builder: (context, state) => ReflectionScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
