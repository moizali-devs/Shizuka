import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

const List<String> kRoomCharacters = [
  'Shizuka',
  'Haruto',
  'Yuki',
  'Ren',
  'Aoi',
  'Sora',
];

class RoomMember {
  const RoomMember({
    required this.uid,
    required this.character,
    required this.joinedAt,
  });

  final String uid;
  final String character;
  final DateTime joinedAt;

  factory RoomMember.fromMap(Map<String, dynamic> map) {
    final ts = map['joinedAt'];
    return RoomMember(
      uid: map['uid'] as String,
      character: map['character'] as String,
      joinedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class Room {
  const Room({
    required this.roomId,
    required this.hostUid,
    required this.status,
    required this.createdAt,
    required this.members,
    this.sessionStartedAt,
  });

  final String roomId;
  final String hostUid;
  final String status; // waiting | active | ended
  final DateTime createdAt;
  final Map<String, RoomMember> members;
  final DateTime? sessionStartedAt;

  factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data()!;
    final ts = data['createdAt'];
    final sts = data['sessionStartedAt'];
    final rawMembers = (data['members'] as Map<String, dynamic>?) ?? {};
    final members = rawMembers.map(
      (uid, val) => MapEntry(
        uid,
        RoomMember.fromMap(Map<String, dynamic>.from(val as Map)),
      ),
    );
    return Room(
      roomId: data['roomId'] as String,
      hostUid: data['hostUid'] as String,
      status: data['status'] as String? ?? 'waiting',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      members: members,
      sessionStartedAt: sts is Timestamp ? sts.toDate() : null,
    );
  }
}

/// Characters used when generating room codes. Exported for testing.
const String kRoomCodeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Generates a random 6-character room code from [kRoomCodeChars].
String generateRoomCode() {
  final rng = Random.secure();
  return List.generate(6, (_) => kRoomCodeChars[rng.nextInt(kRoomCodeChars.length)]).join();
}

class RoomRepository {
  RoomRepository({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance;

  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  /// Generates a unique 6-char code, checks Firestore for collisions.
  Future<String> _uniqueCode() async {
    for (var i = 0; i < 10; i++) {
      final code = generateRoomCode();
      final snap = await _firestore.collection('rooms').doc(code).get();
      if (!snap.exists) return code;
    }
    throw Exception('Failed to generate a unique room code after 10 attempts');
  }

  /// Creates a room, assigns the host a character, and sets up the
  /// RTDB onDisconnect hook so status flips to `ended` on host disconnect.
  Future<Room> createRoom(String hostUid) async {
    final code = await _uniqueCode();
    final character = kRoomCharacters.first;
    final now = DateTime.now();

    await _firestore.collection('rooms').doc(code).set({
      'roomId': code,
      'hostUid': hostUid,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'members': {
        hostUid: {
          'uid': hostUid,
          'character': character,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      },
    });

    // RTDB presence: onDisconnect writes false → app listener calls setRoomEnded
    final presenceRef = _database.ref('rooms/$code/hostOnline');
    await presenceRef.onDisconnect().set(false);
    await presenceRef.set(true);

    return Room(
      roomId: code,
      hostUid: hostUid,
      status: 'waiting',
      createdAt: now,
      members: {
        hostUid: RoomMember(uid: hostUid, character: character, joinedAt: now),
      },
    );
  }

  Stream<Room?> watchRoom(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .withConverter<Room?>(
          fromFirestore: (snap, _) => snap.exists ? Room.fromFirestore(snap) : null,
          toFirestore: (_, _) => {},
        )
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Emits `true` while the host is connected, `false` on disconnect.
  Stream<bool> watchHostOnline(String roomId) {
    return _database
        .ref('rooms/$roomId/hostOnline')
        .onValue
        .map((event) => event.snapshot.value == true);
  }

  /// Joins an existing room by [code]. Throws a descriptive [Exception] if the
  /// room doesn't exist or is not in `waiting` status. Assigns the guest a
  /// character not already taken, and adds them to the members map.
  Future<Room> joinRoom(String code, String guestUid) async {
    final roomRef = _firestore.collection('rooms').doc(code.toUpperCase());

    return _firestore.runTransaction<Room>((tx) async {
      final snap = await tx.get(roomRef);

      if (!snap.exists) {
        throw Exception('No room found with code "$code".');
      }

      final room = Room.fromFirestore(snap);

      if (room.status != 'waiting') {
        throw Exception('Room "$code" is no longer accepting members.');
      }

      if (room.members.containsKey(guestUid)) {
        // Already in room — idempotent re-join
        return room;
      }

      final takenCharacters =
          room.members.values.map((m) => m.character).toSet();
      final available = kRoomCharacters
          .firstWhere(
            (c) => !takenCharacters.contains(c),
            orElse: () => throw Exception('Room "$code" is full.'),
          );

      tx.update(roomRef, {
        'members.$guestUid': {
          'uid': guestUid,
          'character': available,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      });

      final now = DateTime.now();
      final updatedMembers = Map<String, RoomMember>.from(room.members)
        ..[guestUid] =
            RoomMember(uid: guestUid, character: available, joinedAt: now);

      return Room(
        roomId: room.roomId,
        hostUid: room.hostUid,
        status: room.status,
        createdAt: room.createdAt,
        members: updatedMembers,
      );
    });
  }

  /// Transitions room to `active` and records when the session started.
  Future<void> startSession(String roomId) {
    return _firestore.collection('rooms').doc(roomId).update({
      'status': 'active',
      'sessionStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setRoomEnded(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .update({'status': 'ended'});
  }
}
