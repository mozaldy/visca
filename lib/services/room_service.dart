import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:visca/models/room_model.dart';

class RoomService {
  final CollectionReference _roomsCollection = FirebaseFirestore.instance
      .collection('rooms');

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
    final querySnapshot =
        await _roomsCollection
            .where('ownerId', isEqualTo: ownerId)
            .orderBy('createdAt', descending: true)
            .get();

    return querySnapshot.docs
        .map(
          (doc) =>
              RoomModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> updateRoom(RoomModel room) async {
    await _roomsCollection.doc(room.id).update(room.toMap());
  }

  Future<void> deleteRoom(String roomId) async {
    await _roomsCollection.doc(roomId).delete();
  }

  Future<void> addMemberNameToRoom(String roomId, String memberName) async {
    // Adds a member name to the 'members' array in the RoomModel document in Firebase.
    // FieldValue.arrayUnion ensures the name is only added if it's not already present.
    try {
      await _roomsCollection.doc(roomId).update({
        'members': FieldValue.arrayUnion([memberName]),
      });
      print('Member "$memberName" added to Firebase room "$roomId"');
    } catch (e) {
      print('Error adding member "$memberName" to Firebase room "$roomId": $e');
      // Rethrow or handle as appropriate for your app's error handling strategy
      rethrow;
    }
  }

  Future<void> removeMemberNameFromRoom(
    String roomId,
    String memberName,
  ) async {
    // Optional: if you need to remove a member from the Firebase list
    try {
      await _roomsCollection.doc(roomId).update({
        'members': FieldValue.arrayRemove([memberName]),
      });
      print('Member "$memberName" removed from Firebase room "$roomId"');
    } catch (e) {
      print(
        'Error removing member "$memberName" from Firebase room "$roomId": $e',
      );
      rethrow;
    }
  }

  // It's also good practice to have a stream for real-time updates of a room if needed
  Stream<RoomModel?> getRoomStream(String roomId) {
    return _roomsCollection.doc(roomId).snapshots().map((doc) {
      if (doc.exists) {
        return RoomModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
