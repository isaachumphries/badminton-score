import 'package:flutter/foundation.dart';

import '../engine/match.dart';

class MatchController extends ChangeNotifier {
  MatchController(this.config) : _state = deriveMatch(config, const []);

  final MatchConfig config;
  final List<MatchEvent> _events = [];
  MatchState _state;

  MatchState get state => _state;
  bool get canUndo => _events.isNotEmpty;

  /// Appends [e] if valid; returns whether it was accepted.
  bool push(MatchEvent e) {
    if (!canAcceptEvent(config, _events, e)) return false;
    _events.add(e);
    _refresh();
    return true;
  }

  void undo() {
    if (_events.isEmpty) return;
    _events.removeLast();
    _refresh();
  }

  void _refresh() {
    _state = deriveMatch(config, _events);
    notifyListeners();
  }
}
