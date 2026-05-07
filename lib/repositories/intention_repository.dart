import 'package:cloud_firestore/cloud_firestore.dart';

class Intention {
  const Intention({
    required this.uid,
    required this.text,
    required this.submittedAt,
  });

  final String uid;
  final String text;
  final DateTime submittedAt;

  factory Intention.fromMap(Map<String, dynamic> map) {
    final ts = map['submittedAt'];
    return Intention(
      uid: map['uid'] as String,
      text: map['text'] as String,
      submittedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class IntentionRepository {
  IntentionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> submitIntention({
    required String roomId,
    required String uid,
    required String text,
  }) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('intentions')
        .doc(uid)
        .set({
      'uid': uid,
      'text': text.trim(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams all submitted intentions for a room as a uid→Intention map.
  Stream<Map<String, Intention>> watchIntentions(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('intentions')
        .snapshots()
        .map(
          (snap) => {
            for (final doc in snap.docs)
              doc.id: Intention.fromMap(doc.data()),
          },
        );
  }
}
