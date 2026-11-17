import '../engine/match.dart';
import '../engine/types.dart';

String playerName(MatchConfig c, PlayerId p) => c.names[p] ?? p.name;

String teamName(MatchConfig c, Side s) {
  final ids = c.format == Format.singles
      ? [s == Side.a ? PlayerId.a1 : PlayerId.b1]
      : [s == Side.a ? PlayerId.a1 : PlayerId.b1, s == Side.a ? PlayerId.a2 : PlayerId.b2];
  return ids.map((p) => playerName(c, p)).join(' & ');
}

/// Umpire-style call: server's score first.
String scoreCall(MatchState s) {
  final server = s.rally.server.side;
  final mine = s.rally.scores[server]!;
  final theirs = s.rally.scores[server.other]!;
  if (mine == theirs) return mine == 0 ? 'Love all' : '$mine all';
  return '$mine – $theirs';
}

String serveLine(MatchConfig c, MatchState s) {
  final court = s.rally.positions[s.rally.server]!.name;
  return '${playerName(c, s.rally.server)} serves from the $court '
      'to ${playerName(c, s.rally.receiver)}';
}

String? cueLabel(MatchConfig c, Cue cue) => switch (cue) {
      ChangeEndsCue() => 'Change ends',
      IntervalCue(:final seconds) => 'Interval · $seconds s',
      GamePointCue(:final side) => 'Game point · ${teamName(c, side)}',
      MatchPointCue(:final side) => 'Match point · ${teamName(c, side)}',
      GameWonCue() || MatchWonCue() => null,
    };
