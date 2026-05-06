import 'package:go_router/go_router.dart';
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

final appRouter = GoRouter(
  initialLocation: '/splash',
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
      path: '/lobby',
      name: 'lobby',
      builder: (context, state) => const LobbyScreen(),
    ),
    GoRoute(
      path: '/session',
      name: 'session',
      builder: (context, state) => const SessionScreen(),
    ),
    GoRoute(
      path: '/check-in',
      name: 'check_in',
      builder: (context, state) => const CheckInScreen(),
    ),
    GoRoute(
      path: '/break',
      name: 'break_screen',
      builder: (context, state) => const BreakScreen(),
    ),
    GoRoute(
      path: '/reflection',
      name: 'reflection',
      builder: (context, state) => const ReflectionScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
