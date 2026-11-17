import 'package:badminton_score/engine/match.dart';
import 'package:badminton_score/engine/rulesets.dart';
import 'package:badminton_score/engine/types.dart';
import 'package:flutter_test/flutter_test.dart';

MatchConfig cfg([Ruleset r = bwf21]) => MatchConfig(
      format: Format.doubles,
      ruleset: r,
      names: {for (final p in PlayerId.values) p: p.name},
      firstServer: PlayerId.a1,
      firstReceiver: PlayerId.b1,
      leftEndSide: Side.a,
    );

List<MatchEvent> pts(Side s, int n) => List.generate(n, (_) => PointEvent(s));
const next = StartGameEvent(PlayerId.a1, PlayerId.b1);

/// Alternating points ending at a-b (a <= b or not), a scoring first.
List<MatchEvent> score(int a, int b) =>
    [...pts(Side.a, a), ...pts(Side.b, b)];

void main() {
  test('game won -> betweenGames with GameWonCue', () {
    final s = deriveMatch(cfg(), pts(Side.a, 21));
    expect(s.status, MatchStatus.betweenGames);
    expect(s.gamesWon[Side.a], 1);
    expect(s.cues, contains(const GameWonCue(Side.a)));
  });

  test('interval cue fires once per game', () {
    final events = pts(Side.a, 10);
    expect(deriveMatch(cfg(), events).cues, isEmpty);
    final at11 = deriveMatch(cfg(), [...events, PointEvent(Side.a)]);
    expect(at11.cues, contains(const IntervalCue(60)));
    final at12 = deriveMatch(cfg(), [...events, ...pts(Side.a, 2)]);
    expect(at12.cues.whereType<IntervalCue>(), isEmpty);
  });

  test('game point cues', () {
    expect(deriveMatch(cfg(), score(20, 19)).cues,
        contains(const GamePointCue(Side.a)));
    expect(
        deriveMatch(cfg(), score(20, 20)).cues.whereType<GamePointCue>(),
        isEmpty);
    // interleave to reach 29-29
    final e = <MatchEvent>[];
    for (var i = 0; i < 29; i++) {
      e..add(PointEvent(Side.a))..add(PointEvent(Side.b));
    }
    final cues = deriveMatch(cfg(), e).cues;
    expect(cues, containsAll([const GamePointCue(Side.a), const GamePointCue(Side.b)]));
  });

  test('bwf21 30-29 cap: next point at 29-29 wins', () {
    final e = <MatchEvent>[];
    for (var i = 0; i < 29; i++) {
      e..add(PointEvent(Side.a))..add(PointEvent(Side.b));
    }
    expect(deriveMatch(cfg(), e).status, MatchStatus.playing);
    expect(deriveMatch(cfg(), [...e, PointEvent(Side.b)]).status,
        MatchStatus.betweenGames);
  });

  test('match won after two games, further points rejected', () {
    final e = [...pts(Side.a, 21), next, ...pts(Side.a, 21)];
    final s = deriveMatch(cfg(), e);
    expect(s.status, MatchStatus.finished);
    expect(s.winner, Side.a);
    expect(s.cues, contains(const MatchWonCue(Side.a)));
    expect(canAcceptEvent(cfg(), e, PointEvent(Side.a)), isFalse);
  });

  List<MatchEvent> toGame3() =>
      [...pts(Side.a, 21), next, ...pts(Side.b, 21), next];

  test('game 3 change of ends once, at 11', () {
    final base = toGame3();
    expect(deriveMatch(cfg(), base).leftEndSide, Side.a);
    final at11 = deriveMatch(cfg(), [...base, ...pts(Side.b, 11)]);
    expect(at11.cues, contains(const ChangeEndsCue()));
    expect(at11.leftEndSide, Side.b);
    final other = deriveMatch(
        cfg(), [...base, ...pts(Side.b, 11), ...pts(Side.a, 11)]);
    expect(other.cues.whereType<ChangeEndsCue>(), isEmpty);
    expect(other.leftEndSide, Side.b);
  });

  test('bwf15 change of ends at 8', () {
    final base = [...pts(Side.a, 15), next, ...pts(Side.b, 15), next];
    final s = deriveMatch(cfg(bwf15), [...base, ...pts(Side.a, 8)]);
    expect(s.cues, contains(const ChangeEndsCue()));
  });

  test('no change of ends in game 1 or 2 at 11', () {
    expect(deriveMatch(cfg(), pts(Side.a, 11)).cues.whereType<ChangeEndsCue>(),
        isEmpty);
  });

  test('startGame flips left end for game 2', () {
    final s = deriveMatch(cfg(), [...pts(Side.a, 21), next]);
    expect(s.gameNumber, 2);
    expect(s.leftEndSide, Side.b);
    expect(s.status, MatchStatus.playing);
  });

  test('match point vs game point', () {
    final g1 = [...pts(Side.a, 21), next];
    final mp = deriveMatch(cfg(), [...g1, ...pts(Side.a, 10), ...pts(Side.b, 0), ...pts(Side.a, 10)]);
    expect(mp.cues, contains(const MatchPointCue(Side.a)));
    final e = <MatchEvent>[...g1];
    for (var i = 0; i < 19; i++) {
      e..add(PointEvent(Side.a))..add(PointEvent(Side.b));
    }
    e.add(PointEvent(Side.b)); // b 20, a 19
    final s = deriveMatch(cfg(), e);
    expect(s.cues, contains(const GamePointCue(Side.b)));
    expect(s.cues.whereType<MatchPointCue>().where((c) => c.side == Side.b),
        isEmpty);
  });

  test('undo by replay across boundaries', () {
    final win = [...pts(Side.a, 20)];
    final before = deriveMatch(cfg(), win);
    final after = deriveMatch(cfg(), [...win, PointEvent(Side.a)]);
    expect(after.status, MatchStatus.betweenGames);
    final undone = deriveMatch(cfg(), win);
    expect(undone.status, MatchStatus.playing);
    expect(undone.rally.scores, before.rally.scores);
    final withStart = [...win, PointEvent(Side.a), next];
    expect(deriveMatch(cfg(), withStart).status, MatchStatus.playing);
    expect(deriveMatch(cfg(), withStart.sublist(0, withStart.length - 1)).status,
        MatchStatus.betweenGames);
  });

  test('defaultNextServe after A wins game 1', () {
    final s = deriveMatch(cfg(), pts(Side.a, 21));
    final n = defaultNextServe(cfg(), s);
    expect(n.server.side, Side.a);
    expect(n.receiver.side, Side.b);
    expect(n.server, s.rally.server);
    expect(n.receiver, s.rally.receiver);
  });

  test('stale log: rejected events are skipped', () {
    final e = [...pts(Side.a, 21), PointEvent(Side.b), PointEvent(Side.b)];
    final s = deriveMatch(cfg(), e);
    expect(s.status, MatchStatus.betweenGames);
    expect(s.rally.scores[Side.b], 0);
  });

  test('StartGameEvent with same-side server/receiver is rejected', () {
    final e = pts(Side.a, 21);
    const bad = StartGameEvent(PlayerId.a1, PlayerId.a2);
    expect(canAcceptEvent(cfg(), e, bad), isFalse);
    expect(deriveMatch(cfg(), [...e, bad]).status, MatchStatus.betweenGames);
    expect(canAcceptEvent(cfg(), e, next), isTrue);
  });
}
