import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visca/models/attendance_model.dart';
import 'package:visca/models/room_model.dart';

class OnGoingAttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  final int totalMembers;
  final VoidCallback onClose;
  final VoidCallback onOpenCamera;

  const OnGoingAttendanceCard({
    super.key,
    required this.attendance,
    required this.totalMembers,
    required this.onClose,
    required this.onOpenCamera,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('h:mm a, d MMM yyyy');

    return Container(
      height: 135,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attendance.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF01313C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Number of Attendees : ${attendance.totalCheckedIn}/$totalMembers',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4C7273),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Opened At : ${dateFormat.format(attendance.openedAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86B9B0),
            ),
          ),
          Text(
            'Closed At : ${attendance.closedAt != null ? dateFormat.format(attendance.closedAt!) : "-"}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF86B9B0),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 21,
                width: 90,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Close Session',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 21,
                width: 90,
                child: ElevatedButton.icon(
                  onPressed: onOpenCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                  label: const Text(
                    'Open Cam',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Color(0xFF01313C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
