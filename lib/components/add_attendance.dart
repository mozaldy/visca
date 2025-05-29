import 'package:flutter/material.dart';

class AddAttendanceDialog extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController dateController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const AddAttendanceDialog({
    Key? key,
    required this.titleController,
    required this.dateController,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Attendance Title',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'e.g., "Weekly Meeting"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(
              hintText: 'Enter Date (YYYY-MM-DD)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
