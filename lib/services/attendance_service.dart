import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visca/models/attendance_model.dart';

class AttendanceService {
  final CollectionReference _attendanceCollection = FirebaseFirestore.instance
      .collection('attendances');

  Future<String> createAttendance(AttendanceModel attendance) async {
    final docRef = _attendanceCollection.doc();
    final attendanceWithId = AttendanceModel(
      id: docRef.id,
      roomId: attendance.roomId,
      ownerId: attendance.ownerId,
      name: attendance.name,
      openedAt: attendance.openedAt,
      duration: attendance.duration,
      closedAt: attendance.closedAt,
      totalCheckedIn: attendance.totalCheckedIn,
      checkedInUsers: attendance.checkedInUsers,
    );
    await docRef.set(attendanceWithId.toMap());
    return docRef.id;
  }

  Future<AttendanceModel?> getAttendance(String attendanceId) async {
    final doc = await _attendanceCollection.doc(attendanceId).get();
    if (doc.exists) {
      return AttendanceModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    }
    return null;
  }

  Future<List<AttendanceModel>> getAttendancesByRoom(String roomId) async {
    final querySnapshot =
        await _attendanceCollection
            .where('roomId', isEqualTo: roomId)
            .orderBy('openedAt', descending: true)
            .get();

    return querySnapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<AttendanceModel>> getAttendancesByOwner(String ownerId) async {
    final snapshot =
        await _attendanceCollection.where('ownerId', isEqualTo: ownerId).get();

    final now = DateTime.now();

    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .where(
          (attendance) =>
              attendance.closedAt != null && attendance.closedAt.isAfter(now),
        ) // filter aktif di Dart
        .toList();
  }

  Future<int> getAttendanceCountForRoom(String roomId) async {
    final snapshot =
        await _attendanceCollection.where('roomId', isEqualTo: roomId).get();

    return snapshot.docs.length;
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _attendanceCollection.doc(attendance.id).update(attendance.toMap());
  }

  Future<void> deleteAttendance(String attendanceId) async {
    await _attendanceCollection.doc(attendanceId).delete();
  }

  Future<void> addCheckedInUser(String attendanceId, String userId) async {
    await _attendanceCollection.doc(attendanceId).update({
      'checkedInUsers': FieldValue.arrayUnion([userId]),
      'totalCheckedIn': FieldValue.increment(1),
    });
  }

  // Add this method for removing users if needed
  Future<void> removeCheckedInUser(String attendanceId, String userId) async {
    await _attendanceCollection.doc(attendanceId).update({
      'checkedInUsers': FieldValue.arrayRemove([userId]),
      'totalCheckedIn': FieldValue.increment(-1),
    });
  }

  // Add this method for real-time updates
  Stream<AttendanceModel> getAttendanceStream(String attendanceId) {
    return _attendanceCollection.doc(attendanceId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Attendance not found');
      }
      return AttendanceModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    });
  }
}
