// import 'package:flutter/material.dart';
// import '../components/delete_attendance.dart';
// import '../components/add_attendance.dart';
// import '../screens/room_detail_member.dart';
//
// class RoomDetailPage extends StatefulWidget {
//   final String roomName;
//
//   const RoomDetailPage({required this.roomName, Key? key}) : super(key: key);
//
//   @override
//   _RoomDetailPageState createState() => _RoomDetailPageState();
// }
//
// class _RoomDetailPageState extends State<RoomDetailPage> {
//   final List<Map<String, String>> attendances = [];
//
//   void _showAddAttendanceDialog() {
//     final titleController = TextEditingController();
//     final dateController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder:
//           (_) => AddAttendanceDialog(
//             titleController: titleController,
//             dateController: dateController,
//             onCancel: () => Navigator.pop(context),
//             onSave: () {
//               setState(() {
//                 attendances.add({
//                   'title': titleController.text,
//                   'date': dateController.text,
//                 });
//               });
//               Navigator.pop(context);
//             },
//           ),
//     );
//   }
//
//   void _showDeleteDialog(int index) {
//     showDialog(
//       context: context,
//       builder:
//           (_) => DeleteAttendanceDialog(
//             onCancel: () => Navigator.pop(context),
//             onDelete: () {
//               setState(() {
//                 attendances.removeAt(index);
//               });
//               Navigator.pop(context);
//             },
//           ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF2E5C58),
//         title: Text(widget.roomName),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.people),
//             tooltip: 'Member Detailsz',
//             onPressed: () {
//               print('Member details pressed');
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder:
//                       (_) => RoomDetailMemberPage(roomName: widget.roomName),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       backgroundColor: const Color(0xFFF5F5F5),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 16),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Attendance History',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   SizedBox(
//                     height: 360,
//                     child: ListView.builder(
//                       itemCount: attendances.length,
//                       itemBuilder: (context, index) {
//                         final att = attendances[index];
//                         return Card(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           margin: const EdgeInsets.symmetric(vertical: 4),
//                           child: ListTile(
//                             title: Text(att['title'] ?? ''),
//                             subtitle: Text(att['date'] ?? ''),
//                             trailing: PopupMenuButton<String>(
//                               onSelected: (value) {
//                                 if (value == 'delete') {
//                                   _showDeleteDialog(index);
//                                 }
//                               },
//                               itemBuilder:
//                                   (context) => const [
//                                     PopupMenuItem(
//                                       value: 'delete',
//                                       child: Text('Delete'),
//                                     ),
//                                   ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddAttendanceDialog,
//         backgroundColor: const Color(0xFF2E5C58),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
