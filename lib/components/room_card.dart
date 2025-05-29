import 'package:flutter/material.dart';
import 'package:visca/models/room_model.dart';
import 'package:visca/services/attendance_service.dart';

class RoomCard extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onEnterRoom;

  const RoomCard({
    Key? key,
    required this.room,
    required this.onEnterRoom,
  }) : super(key: key);

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  final AttendanceService attendanceService = AttendanceService();
  int attendanceCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceCount();
  }

  void _loadAttendanceCount() async {
    int count = await attendanceService.getAttendanceCountForRoom(widget.room.id);
    if (mounted) {
      setState(() {
        attendanceCount = count;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 104,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Title & Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.room.name,
                style: const TextStyle(
                  color: Color(0xFF01313C),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Members: ${widget.room.members.length}",
                style: const TextStyle(color: Color(0xFF86B9B0)),
              ),
              const SizedBox(height: 2),
              Text(
                isLoading ? "Attendance: ..." : "Attendance: $attendanceCount",
                style: const TextStyle(color: Color(0xFF86B9B0)),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: ElevatedButton(
              onPressed: widget.onEnterRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01313C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Enter Room", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
