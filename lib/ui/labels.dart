import '../engine/match.dart';
import '../engine/types.dart';

String playerName(MatchConfig c, PlayerId p) => c.names[p] ?? p.name;

String teamName(MatchConfig c, Side s) {
  final ids = c.format == Format.singles
      ? [s == Side.a ? PlayerId.a1 : PlayerId.b1]
      : [s == Side.a ? PlayerId.a1 : PlayerId.b1, s == Side.a ? PlayerId.a2 : PlayerId.b2];
  return ids.map((p) => playerName(c, p)).join(' & ');
}

/// Marker labels for two teammates: one letter each unless both start with
/// the same letter. Then a two-word name adds its second word's initial and a
/// one-word name adds its 2nd letter (3rd if that still clashes); if nothing
/// tells them apart, they become e.g. M1 and M2.
(String, String) teammateInitials(String a, String b) {
  final x = a.trim(), y = b.trim();
  String letter(String s, int i) => String.fromCharCode(s.runes.elementAt(i));
  String first(String s) => s.isEmpty ? '?' : letter(s, 0).toUpperCase();
  if (first(x) != first(y)) return (first(x), first(y));

  String? pair(String s, int index) {
    final words = s.split(RegExp(r'\s+'));
    if (words.length > 1) return first(s) + first(words[1]);
    return s.runes.length > index ? first(s) + letter(s, index).toLowerCase() : null;
  }

  for (final i in [1, 2]) {
    final p = pair(x, i), q = pair(y, i);
    if (p != null && q != null && p.toUpperCase() != q.toUpperCase()) {
      return (p, q);
    }
  }
  return ('${first(x)}1', '${first(y)}2');
}

String playerInitials(MatchConfig c, PlayerId p) {
  if (c.format == Format.singles) {
    return teammateInitials(playerName(c, p), '').$1;
  }
  // Always pass the pair in the same order so the 1/2 fallback is stable.
  final lead = p.side == Side.a ? PlayerId.a1 : PlayerId.b1;
  final (one, two) =
      teammateInitials(playerName(c, lead), playerName(c, lead.partner));
  return p == lead ? one : two;
}

/// "21 points · cap 30", "11 points · win by 2", "11 points".
String rulesetMeta(Ruleset r) {
  final pts = '${r.pointsToWin} points';
  if (r.id != 'custom') return '$pts · cap ${r.cap}';
  return r.cap > r.pointsToWin ? '$pts · win by 2' : pts;
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
