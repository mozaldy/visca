import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visca/components/checkedIn_users_card.dart';
import 'package:visca/models/attendance_model.dart';
import 'package:visca/models/room_model.dart'; // Added
import 'package:visca/services/room_service.dart'; // Added

class AttendanceDetailScreen extends StatefulWidget {
  // Changed to StatefulWidget
  final AttendanceModel attendance;

  const AttendanceDetailScreen({Key? key, required this.attendance})
    : super(key: key);

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  RoomModel? _room;
  List<String> _notCheckedInUsers = [];
  bool _isLoadingRoom = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRoomDetailsAndCalculateNotCheckedIn();
  }

  Future<void> _fetchRoomDetailsAndCalculateNotCheckedIn() async {
    setState(() {
      _isLoadingRoom = true;
      _errorMessage = null;
    });
    try {
      final roomDetails = await RoomService().getRoom(widget.attendance.roomId);
      if (mounted) {
        if (roomDetails != null) {
          final allMembers = roomDetails.members;
          // Ensure checkedInUsers is not null, default to empty list if it is
          final checkedInUsers = widget.attendance.checkedInUsers ?? [];
          final notCheckedIn =
              allMembers
                  .where((member) => !checkedInUsers.contains(member))
                  .toList();
          setState(() {
            _room = roomDetails;
            _notCheckedInUsers = notCheckedIn;
            _isLoadingRoom = false;
          });
        } else {
          setState(() {
            _isLoadingRoom = false;
            _errorMessage = 'Room details not found.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoom = false;
          _errorMessage = 'Error fetching room details: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        widget.attendance.openedAt != null
            ? DateFormat('dd/MM/yy').format(widget.attendance.openedAt!)
            : '-';

    // Ensure checkedInUsers is not null, default to empty list if it is
    final checkedInUsers = widget.attendance.checkedInUsers ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header (remains the same)
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
                          widget.attendance.name,
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
                        if (_room !=
                            null) // Display total members if room data is available
                          Text(
                            'Total Members: ${_room!.members.length}',
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

          // Body content
          Expanded(
            child: Container(
              color: const Color(0xFF8FD7D9),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child:
                    _isLoadingRoom
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Center(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                        : SingleChildScrollView(
                          // Added SingleChildScrollView
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Checked In Users Section
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
                              if (checkedInUsers.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text('No users have checked in yet.'),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap:
                                      true, // Important for SingleChildScrollView
                                  physics:
                                      const NeverScrollableScrollPhysics(), // Important for SingleChildScrollView
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: checkedInUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = checkedInUsers[index];
                                    return CheckedInUsersCard(
                                      checkedInUsers: user,
                                    );
                                  },
                                ),

                              // Not Checked In Users Section
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                                child: Text(
                                  'Not Checked In Users',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_notCheckedInUsers.isEmpty &&
                                  checkedInUsers.length ==
                                      (_room?.members.length ?? 0))
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text('All members have checked in.'),
                                )
                              else if (_notCheckedInUsers.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'No users pending check-in or room members list is empty.',
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap:
                                      true, // Important for SingleChildScrollView
                                  physics:
                                      const NeverScrollableScrollPhysics(), // Important for SingleChildScrollView
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: _notCheckedInUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = _notCheckedInUsers[index];
                                    return CheckedInUsersCard(
                                      checkedInUsers: user,
                                    );
                                  },
                                ),
                              const SizedBox(
                                height: 20,
                              ), // Add some padding at the bottom
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
