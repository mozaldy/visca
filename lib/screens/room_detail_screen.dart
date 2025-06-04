import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visca/components/attendance_card.dart';
import 'package:visca/components/create_attendance_dialog.dart';
import 'package:visca/components/delete_attendance.dart';
import 'package:visca/components/onGoing_attendance_card.dart';
import 'package:visca/features/face_recognition/face_detector_view.dart';
import 'package:visca/models/attendance_model.dart';
import 'package:visca/screens/attendance_detail_screen.dart';
import 'package:visca/screens/room_detail_member.dart';
import 'package:visca/services/attendance_service.dart';
import 'package:visca/services/room_service.dart';
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

  void _showDeleteDialog(String attendanceId) {
    showDialog(
      context: context,
      builder:
          (_) => DeleteAttendanceDialog(
            onCancel: () => Navigator.pop(context),
            onDelete: () async {
              await attendanceService.deleteAttendance(attendanceId);
              setState(() {});
              Navigator.pop(context);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yy').format(widget.room.createdAt);
    void _onOpenCamera(AttendanceModel attendance) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceDetectorView(attendance: attendance),
        ),
      );
    }

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

          Expanded(
            child: Container(
              color: const Color(0xFF8FD7D9),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // On Going Title
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'On Going Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // On Going Attendance List
                      FutureBuilder<List<AttendanceModel>>(
                        future: AttendanceService().getActiveAttendancesByRoom(
                          widget.room.id,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('There is no attendance in progress'),
                            );
                          }

                          final attendanceList = snapshot.data!;
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            itemCount: attendanceList.length,
                            itemBuilder: (context, index) {
                              final attendance = attendanceList[index];

                              return FutureBuilder<RoomModel?>(
                                future: RoomService().getRoom(
                                  attendance.roomId,
                                ),

                                builder: (context, roomSnapshot) {
                                  print(
                                    'Build tombol Close Session untuk ${attendance.id}',
                                  );

                                  if (roomSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return OnGoingAttendanceCard(
                                      attendance: attendance,
                                      totalMembers: widget.room.members.length,

                                      onClose: () async {
                                        print(
                                          'Updating closedAt for: ${attendance.id}',
                                        );
                                        await AttendanceService()
                                            .updateAttendanceClosedAt(
                                              attendance.id,
                                            );
                                        print('Done updating.');
                                        setState(() {});
                                      },
                                      onOpenCamera:
                                          () => _onOpenCamera(attendance),
                                    );
                                  }

                                  final room = roomSnapshot.data;
                                  return OnGoingAttendanceCard(
                                    attendance: attendance,
                                    totalMembers: room?.members.length ?? 0,
                                    onClose: () async {
                                      print(
                                        'Updating closedAt for: ${attendance.id}',
                                      );
                                      await AttendanceService()
                                          .updateAttendanceClosedAt(
                                            attendance.id,
                                          );
                                      print('Done updating.');
                                      setState(
                                        () {},
                                      ); // refresh tampilan jika perlu
                                    },
                                    onOpenCamera:
                                        () => _onOpenCamera(attendance),
                                  );
                                },
                              );
                            },
                            separatorBuilder:
                                (context, index) => const SizedBox(height: 12),
                          );
                        },
                      ),

                      // Attendance History Title
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          "Attendance History",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01313C),
                          ),
                        ),
                      ),

                      // Attendance History List
                      FutureBuilder<List<AttendanceModel>>(
                        future: attendanceService.getAttendancesByRoom(
                          widget.room.id,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          // Ambil semua data attendances
                          final allAttendances = snapshot.data ?? [];

                          // Filter attendance yang closedAt <= sekarang
                          final now = DateTime.now();
                          final attendances =
                              allAttendances.where((attendance) {
                                if (attendance.closedAt == null) return false;
                                return attendance.closedAt!.isBefore(now) ||
                                    attendance.closedAt!.isAtSameMomentAs(now);
                              }).toList();

                          if (attendances.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('No attendance found.'),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: attendances.length,
                            itemBuilder: (context, index) {
                              final attendance = attendances[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AttendanceCard(
                                  attendance: attendance,
                                  amountMembers: widget.room.members.length,
                                  onEdit: () {
                                    print(
                                      "Navigating to AttendanceDetailScreen with: ${attendance.name}",
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AttendanceDetailScreen(
                                              attendance: attendance,
                                            ),
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    _showDeleteDialog(attendance.id);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
