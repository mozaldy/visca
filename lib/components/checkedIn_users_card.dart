import 'package:flutter/material.dart';

class CheckedInUsersCard extends StatelessWidget {
  final String checkedInUsers;

  const CheckedInUsersCard({Key? key, required this.checkedInUsers})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (checkedInUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No users checked in.'),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Left text section
          Expanded(
            child: Row(
              children: [
                Text(
                  checkedInUsers,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF01313C),
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
