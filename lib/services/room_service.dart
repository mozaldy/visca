import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visca/models/room_model.dart';

class RoomService {
  final CollectionReference _roomsCollection =
      FirebaseFirestore.instance.collection('rooms');

  Future<String> createRoom(RoomModel room) async {
    final docRef = _roomsCollection.doc(); 
    final roomWithId = RoomModel(
      id: docRef.id,
      name: room.name,
      ownerId: room.ownerId,
      members: room.members,
      createdAt: room.createdAt,
    );

    await docRef.set(roomWithId.toMap());
    return docRef.id;
  }

  Future<RoomModel?> getRoom(String roomId) async {
    final doc = await _roomsCollection.doc(roomId).get();
    if (doc.exists) {
      return RoomModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<RoomModel>> getRoomsByOwner(String ownerId) async {
    final querySnapshot = await _roomsCollection
        .where('ownerId', isEqualTo: ownerId) 
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => RoomModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRoom(RoomModel room) async {
    await _roomsCollection.doc(room.id).update(room.toMap());
  }

  Future<void> deleteRoom(String roomId) async {
    await _roomsCollection.doc(roomId).delete();
  }
}
