import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> members;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.createdAt,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> data) {
    return RoomModel(
      id: id,
      name: data['name'],
      ownerId: data['ownerId'],
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
