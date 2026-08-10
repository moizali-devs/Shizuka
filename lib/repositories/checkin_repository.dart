import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  const CheckIn({
    required this.uid,
    required this.blockNumber,
    required this.text,
    required this.submittedAt,
  });

  final String uid;
  final int blockNumber;
  final String text;
  final DateTime submittedAt;

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    final ts = map['submittedAt'];
    return CheckIn(
      uid: map['uid'] as String,
      blockNumber: (map['blockNumber'] as num).toInt(),
      text: map['text'] as String,
      submittedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class CheckInRepository {
  CheckInRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _checkIns(String roomId) =>
      _firestore.collection('rooms').doc(roomId).collection('checkins');

  /// Writes (or overwrites) a check-in response for [uid] on [blockNumber].
  /// Document ID: `{blockNumber}_{uid}`, unique per member per block.
  Future<void> submitCheckIn({
    required String roomId,
    required String uid,
    required int blockNumber,
    required String text,
  }) {
    return _checkIns(roomId).doc('${blockNumber}_$uid').set({
      'uid': uid,
      'blockNumber': blockNumber,
      'text': text.trim(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams all check-ins for [blockNumber] as a uid → CheckIn map.
  Stream<Map<String, CheckIn>> watchCheckIns(
      String roomId, int blockNumber) {
    return _checkIns(roomId)
        .where('blockNumber', isEqualTo: blockNumber)
        .snapshots()
        .map(
          (snap) => {
            for (final doc in snap.docs)
              (doc.data()['uid'] as String): CheckIn.fromMap(doc.data()),
          },
        );
  }
}
