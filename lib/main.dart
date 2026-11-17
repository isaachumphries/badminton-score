import 'package:flutter/material.dart';

void main() => runApp(const BadmintonApp());

class BadmintonApp extends StatelessWidget {
  const BadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Badminton'))),
    );
  }
}
