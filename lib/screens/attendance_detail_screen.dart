import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visca/components/checkedIn_users_card.dart';
import 'package:visca/models/attendance_model.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final AttendanceModel attendance;

  const AttendanceDetailScreen({Key? key, required this.attendance})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        attendance.openedAt != null
            ? DateFormat('dd/MM/yy').format(attendance.openedAt!)
            : '-';

    final checkedInUsers = attendance.checkedInUsers ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
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
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Opened at: $formattedDate',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body content with title + list or no data message
          Expanded(
            child: Container(
              color: const Color(0xFF8FD7D9),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Checked In Users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: checkedInUsers.length,
                        itemBuilder: (context, index) {
                          final user = checkedInUsers[index];
                          return CheckedInUsersCard(checkedInUsers: user);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
