import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.streak,
    this.lastActiveDate,
  });

  final String uid;
  final String email;
  final int streak;
  final DateTime? lastActiveDate;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final ts = map['lastActiveDate'];
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      lastActiveDate: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.date,
    required this.durationMinutes,
    required this.memberCount,
    this.blockCount = 0,
    this.reflectionText,
  });

  final String id;
  final DateTime date;
  final int durationMinutes;
  final int memberCount;
  final int blockCount;
  final String? reflectionText;

  factory SessionSummary.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return SessionSummary(
      id: id,
      date: ts is Timestamp ? ts.toDate() : DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      blockCount: (map['blockCount'] as num?)?.toInt() ?? 0,
      reflectionText: map['reflectionText'] as String?,
    );
  }
}

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserProfile.fromMap(snap.data()!) : null);
  }

  Stream<List<SessionSummary>> watchSessions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reflections')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SessionSummary.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> updateStreak(
    String uid, {
    required int streak,
    required DateTime lastActiveDate,
  }) {
    return _firestore.collection('users').doc(uid).update({
      'streak': streak,
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
    });
  }
}
