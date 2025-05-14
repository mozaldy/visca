import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:visca/screens/home_screen.dart';
import 'package:visca/screens/profile_screen.dart';
import 'package:visca/screens/room_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  BottomNavBarState createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [HomePage(), Room(), Profile()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(
          context,
        ).copyWith(iconTheme: IconThemeData(color: Colors.white)),
        child: CurvedNavigationBar(
          color: const Color(0xFF041421),
          backgroundColor: Colors.transparent,
          animationCurve: Curves.ease,
          buttonBackgroundColor: Color(0xFF86B9B0),
          onTap: _onItemTapped,
          items: [
            CurvedNavigationBarItem(
              child: Icon(
                LucideIcons.house,
                color:
                    _selectedIndex == 0 ? Color(0xFF041421) : Color(0xFF86B9B0),
              ),
              label: 'Home',
              labelStyle: TextStyle(color: Colors.white),
            ),
            CurvedNavigationBarItem(
              child: Icon(
                LucideIcons.users,
                color:
                    _selectedIndex == 1
                        ? const Color(0xFF041421)
                        : Color(0xFF86B9B0),
              ),
              label: 'Room',
              labelStyle: TextStyle(color: Colors.white),
            ),
            CurvedNavigationBarItem(
              child: Icon(
                LucideIcons.user_round,
                color:
                    _selectedIndex == 2
                        ? const Color(0xFF041421)
                        : Color(0xFF86B9B0),
              ),
              label: 'Profile',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
