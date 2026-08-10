import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shizuka/repositories/auth_repository.dart';
import 'package:shizuka/repositories/checkin_repository.dart';
import 'package:shizuka/repositories/intention_repository.dart';
import 'package:shizuka/repositories/profile_repository.dart';
import 'package:shizuka/repositories/room_repository.dart';
import 'package:shizuka/services/reflection_service.dart';
import 'package:shizuka/services/streak_service.dart';
import 'package:shizuka/services/timer_service.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

final streakServiceProvider = Provider<StreakService>(
  (ref) => StreakService(),
);

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
});

final sessionHistoryProvider = StreamProvider<List<SessionSummary>>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchSessions(user.uid);
});

final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => RoomRepository(),
);

final roomProvider = StreamProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).watchRoom(roomId);
});

final hostOnlineProvider = StreamProvider.family<bool, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).watchHostOnline(roomId);
});

final intentionRepositoryProvider = Provider<IntentionRepository>(
  (ref) => IntentionRepository(),
);

final intentionsProvider =
    StreamProvider.family<Map<String, Intention>, String>((ref, roomId) {
  return ref.watch(intentionRepositoryProvider).watchIntentions(roomId);
});

/// Monitors RTDB `.info/connected`, emits `true` when online, `false` when
/// the device has lost its Firebase Realtime Database connection.
final connectionStateProvider = StreamProvider<bool>((ref) {
  return FirebaseDatabase.instance
      .ref('.info/connected')
      .onValue
      .map((event) => event.snapshot.value == true);
});

final timerServiceProvider = Provider<TimerService>(
  (ref) => TimerService(),
);

final timerStateProvider =
    StreamProvider.family<TimerState?, String>((ref, roomId) {
  return ref.watch(timerServiceProvider).watchTimer(roomId);
});

final reflectionServiceProvider = Provider<ReflectionService>(
  (ref) => ReflectionService(),
);

final checkInRepositoryProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepository(),
);

// Family key: (roomId, blockNumber)
final checkInsProvider =
    StreamProvider.family<Map<String, CheckIn>, (String, int)>(
        (ref, args) {
  return ref
      .watch(checkInRepositoryProvider)
      .watchCheckIns(args.$1, args.$2);
});
