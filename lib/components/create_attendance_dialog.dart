import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visca/models/attendance_model.dart';
import 'package:visca/providers/user_provider.dart';

class AttendanceDialog extends ConsumerStatefulWidget {
  final Function(AttendanceModel)? onSave;
  final String roomId;

  const AttendanceDialog({Key? key, required this.roomId, this.onSave})
    : super(key: key);

  @override
  ConsumerState<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends ConsumerState<AttendanceDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 300,
        height: 265,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Weekly Meeting',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter attendance title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text(
                'Duration (minutes)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter duration in minutes',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Duration must be a number';
                  }
                  return null;
                },
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_titleController.text.trim().isEmpty ||
                          _durationController.text.trim().isEmpty) {
                        return; // Simple check, you can enhance validation
                      }
                      int? duration = int.tryParse(
                        _durationController.text.trim(),
                      );
                      if (duration == null) return;

                      final id =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      final now = DateTime.now();
                      final attendance = AttendanceModel(
                        id: '',
                        roomId: widget.roomId,
                        ownerId: userState.user?.uid ?? '',
                        name: _titleController.text.trim(),
                        openedAt: now,
                        duration: duration,
                        closedAt: now.add(Duration(minutes: duration)),
                        totalCheckedIn: 0,
                        checkedInUsers: [],
                      );

                      widget.onSave!(attendance);
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
