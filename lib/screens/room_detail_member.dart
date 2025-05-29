// screens/room_Detail_member.dart
import 'package:flutter/material.dart';

class RoomDetailMemberPage extends StatelessWidget {
  final String roomName;

  const RoomDetailMemberPage({required this.roomName, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy list member
    final List<String> members = ['Alice', 'Bob', 'Charlie'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Members of $roomName'),
        backgroundColor: const Color(0xFF2E5C58),
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(members[index]),
            ),
          );
        },
      ),
    );
  }
}
