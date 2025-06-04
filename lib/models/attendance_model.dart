import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String roomId;
  final String ownerId;
  final String name;
  final DateTime openedAt;
  final int duration;
  final DateTime closedAt;
  final int totalCheckedIn;
  final List<String> checkedInUsers;

  AttendanceModel({
    required this.id,
    required this.roomId,
    required this.ownerId,
    required this.name,
    required this.openedAt,
    required this.duration,
    required this.closedAt,
    required this.totalCheckedIn,
    required this.checkedInUsers,
  });

  factory AttendanceModel.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceModel(
      id: id,
      roomId: data['roomId'],
      ownerId: data['ownerId'],
      name: data['name'],
      openedAt: (data['openedAt'] as Timestamp).toDate(),
      duration: data['duration'],
      closedAt: (data['closedAt'] as Timestamp).toDate(),
      totalCheckedIn: data['totalCheckedIn'] ?? 0,
      checkedInUsers: List<String>.from(data['checkedInUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'ownerId': ownerId,
      'name': name,
      'openedAt': Timestamp.fromDate(openedAt),
      'duration': duration,
      'closedAt': Timestamp.fromDate(closedAt),
      'totalCheckedIn': totalCheckedIn,
      'checkedInUsers': checkedInUsers,
    };
  }

}
