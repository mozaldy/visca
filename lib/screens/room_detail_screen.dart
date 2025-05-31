import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visca/components/attendance_card.dart';
import 'package:visca/components/create_attendance_dialog.dart';
import 'package:visca/components/delete_attendance.dart';
import 'package:visca/models/attendance_model.dart';
import 'package:visca/screens/room_detail_member.dart';
import 'package:visca/services/attendance_service.dart';
import '../models/room_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final RoomModel room;

  const RoomDetailScreen({Key? key, required this.room}) : super(key: key);

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  final AttendanceService attendanceService = AttendanceService();
  final List<Map<String, String>> attendances = [];

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder:
          (_) => DeleteAttendanceDialog(
            onCancel: () => Navigator.pop(context),
            onDelete: () {
              setState(() {
                attendances.removeAt(index);
              });
              Navigator.pop(context);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yy').format(widget.room.createdAt);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AttendanceDialog(
                roomId: widget.room.id,
                onSave: (attendance) async {
                  await AttendanceService().createAttendance(attendance);
                  setState(() {});
                },
              );
            },
          );
        },
        tooltip: 'Tambah sesi',
        backgroundColor: const Color(0xFF01313C),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      body: Column(
        children: [
          // Header
          Container(
            height: 134,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4C7273), Color(0xFF8FD7D9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Room name & date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.room.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Created at: $formattedDate',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Members Detail button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // aksi members detail
                            print('Member details pressed');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        RoomDetailMemberPage(room: widget.room),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            visualDensity: const VisualDensity(
                              horizontal: 1,
                              vertical: 1,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Members Detail',
                            style: TextStyle(
                              color: Color(0xFF01313C),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Attendance history
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "Attendance History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01313C),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<AttendanceModel>>(
                    future: attendanceService.getAttendancesByRoom(
                      widget.room.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final attendances = snapshot.data ?? [];

                      if (attendances.isEmpty) {
                        return const Center(
                          child: Text('No attendance found.'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: attendances.length,
                        itemBuilder: (context, index) {
                          final attendance = attendances[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AttendanceCard(
                              attendance: attendance,
                              amountMembers: widget.room.members.length,
                              onEdit: () {
                                // Aksi edit
                              },
                              onDelete: () {
                                _showDeleteDialog(index);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
