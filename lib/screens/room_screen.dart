import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visca/components/create_room_dialog.dart';
import 'package:visca/components/room_card.dart';
import 'package:visca/providers/user_provider.dart';
import 'package:visca/screens/room_detail_screen.dart';
import 'package:visca/services/room_service.dart';
import 'package:visca/models/room_model.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

final roomService = RoomService();

class _RoomScreenState extends ConsumerState<RoomScreen> {
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Your Room',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4C7273), Color(0xFF8FD7D9)],
              ),
            ),
          ),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Create New Room button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                margin: EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return CreateRoomDialog(
                              onSave: (roomName) async {
                                final newRoom = RoomModel(
                                  id: '',
                                  name: roomName,
                                  ownerId: userState.user!.email,
                                  members:
                                      [], 
                                  createdAt: DateTime.now(),
                                );

                                final roomId = await roomService.createRoom(
                                  newRoom,
                                );
                                print('Room created with ID: $roomId');
                                setState(
                                  () {},
                                ); 
                              },
                            );
                          },
                        );
                      },

                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF4C7273),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 28, color: Colors.white),
                            SizedBox(width: 16),
                            Text(
                              "Create New Room",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Room List Scrollable
              Expanded(
                child: FutureBuilder<List<RoomModel>>(
                  future: roomService.getRoomsByOwner(userState.user!.email),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No rooms found.'));
                    }

                    final rooms = snapshot.data!;
                    return ListView.builder(
                      padding: EdgeInsets.only(top: 16),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return RoomCard(
                          room: room,
                          onEnterRoom: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => RoomDetailScreen(room: room),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
