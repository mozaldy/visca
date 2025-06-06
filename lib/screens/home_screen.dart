import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visca/components/close_session_dialog.dart';
import 'package:visca/components/onGoing_attendance_card.dart';
import 'package:visca/features/face_recognition/face_detector_view.dart';
import 'package:visca/models/attendance_model.dart';
import 'package:visca/models/room_model.dart';
import 'package:visca/providers/user_provider.dart';
import 'package:visca/services/attendance_service.dart';
import 'package:visca/services/room_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _onOpenCamera(AttendanceModel attendance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceDetectorView(attendance: attendance),
      ),
    );
  }

  Future<bool> showCloseSessionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => CloseSessionDialog(
            onClose: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF4C7273),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4C7273), Color(0xFF8FD7D9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${userState.user!.fullName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Welcome to Visca',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          Image.asset(
                            'assets/images/logo.png',
                            height: 24,
                            width: 24,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  const SizedBox(height: 30),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: const Color(0xFF8FD7D9),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul
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

                      // Scrollable List
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: FutureBuilder<List<AttendanceModel>>(
                            future: AttendanceService().getAttendancesByOwner(
                              userState.user!.uid,
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
                                return const Center(
                                  child: Text('Belum ada absensi berlangsung.'),
                                );
                              }

                              final attendanceList = snapshot.data!;
                              return ListView.separated(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 24,
                                ),
                                itemCount: attendanceList.length,
                                itemBuilder: (context, index) {
                                  final attendance = attendanceList[index];
                                  return FutureBuilder<RoomModel?>(
                                    future: RoomService().getRoom(
                                      attendance.roomId,
                                    ), // You'll need to implement this
                                    builder: (context, roomSnapshot) {
                                      if (roomSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return OnGoingAttendanceCard(
                                          attendance: attendance,
                                          totalMembers: 0, // Loading state
                                          onClose: () async {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((
                                                  _,
                                                ) async {
                                                  final shouldClose =
                                                      await showCloseSessionDialog(
                                                        context,
                                                      );
                                                  if (shouldClose) {
                                                    await AttendanceService()
                                                        .updateAttendanceClosedAt(
                                                          attendance.id,
                                                        );
                                                    setState(() {});
                                                  }
                                                });
                                          },
                                          onOpenCamera:
                                              () => _onOpenCamera(attendance),
                                        );
                                      }

                                      final room = roomSnapshot.data;
                                      return OnGoingAttendanceCard(
                                        attendance: attendance,
                                        totalMembers:
                                            room?.members.length ??
                                            0, // Changed this line
                                        onClose: () async {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) async {
                                                final shouldClose =
                                                    await showCloseSessionDialog(
                                                      context,
                                                    );
                                                if (shouldClose) {
                                                  await AttendanceService()
                                                      .updateAttendanceClosedAt(
                                                        attendance.id,
                                                      );
                                                  setState(() {});
                                                }
                                              });
                                        },
                                        onOpenCamera:
                                            () => _onOpenCamera(attendance),
                                      );
                                    },
                                  );
                                },
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(height: 12),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
