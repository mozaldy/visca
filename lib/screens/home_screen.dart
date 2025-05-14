import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:visca/screens/login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _logout() async {
    await FirebaseAuth.instance.signOut();

    // Use this instead of pushReplacementNamed
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Visca"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Center(child: Text("Home Screen")),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Home Page'),
        ),
        body: Center(
          child: Text(
            'Welcome to Home Page',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
