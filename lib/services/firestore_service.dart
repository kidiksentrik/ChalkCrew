import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_record.dart'; // 이거 중요함!

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> saveAttendance(String date, String? comment) async {
    if (uid == null) return;

    final doc = _db.collection('attendance').doc(uid);
    await doc.set({
      date: comment ?? '',
    }, SetOptions(merge: true));
  }

  Future<Map<String, String?>> loadAttendance() async {
    if (uid == null) return {};

    final doc = await _db.collection('attendance').doc(uid).get();
    final data = doc.data() ?? {};

    return data.map((key, value) => MapEntry(key, value?.toString()));
  }

  Stream<List<AttendanceRecord>> watchAttendance(String uid) {
    return _db.collection('attendance').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return [];

      return data.entries.map((entry) {
        return AttendanceRecord(
          date: DateTime.tryParse(entry.key) ?? DateTime(2000),
          comment: entry.value?.toString(),
        );
      }).toList();
    });
  }

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String? bio,
  }) async {
    final doc = _db.collection('users').doc(uid);
    await doc.set({
      'name': name,
      'bio': bio,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
