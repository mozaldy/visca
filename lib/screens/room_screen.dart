import 'package:flutter/material.dart';

class Room extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Room Page'),
        ),
        body: Center(
          child: Text(
            'Welcome to Room Page',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}