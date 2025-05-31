import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visca/models/attendance_model.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  final int amountMembers;
  final void Function()? onEdit;
  final void Function()? onDelete;

  const AttendanceCard({
    super.key,
    required this.attendance,
    required this.amountMembers,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yy').format(attendance.openedAt);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left text section
          Expanded(
            child: Row(
              children: [
                Text(
                  attendance.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF01313C),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${attendance.totalCheckedIn}/$amountMembers',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4C7273),
                  ),
                ),
              ],
            ),
          ),

          // Date
          Text(
            dateFormatted,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4C7273),
            ),
          ),

          // More button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
