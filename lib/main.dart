import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/match_controller.dart';
import 'engine/match.dart';
import 'ui/scoreboard_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BadmintonApp());
}

class BadmintonApp extends StatefulWidget {
  const BadmintonApp({super.key});

  @override
  State<BadmintonApp> createState() => _BadmintonAppState();
}

class _BadmintonAppState extends State<BadmintonApp> {
  MatchController? _controller;

  void _start(MatchConfig c) => setState(() => _controller = MatchController(c));

  void _reset() => setState(() => _controller = null);

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return MaterialApp(
      title: 'Badminton',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: c == null
          ? SetupScreen(onStart: _start)
          : ScoreboardScreen(controller: c, onNewMatch: _reset),
    );
  }
}
