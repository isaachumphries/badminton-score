import 'package:badminton_score/engine/match.dart';
import 'package:badminton_score/engine/rulesets.dart';
import 'package:badminton_score/engine/types.dart';
import 'package:badminton_score/ui/labels.dart';
import 'package:flutter_test/flutter_test.dart';

MatchConfig cfg(Format f) => MatchConfig(
      format: f,
      ruleset: bwf21,
      names: {
        PlayerId.a1: 'Ann',
        PlayerId.a2: 'Al',
        PlayerId.b1: 'Bob',
        PlayerId.b2: 'Bea',
      },
      firstServer: PlayerId.a1,
      firstReceiver: PlayerId.b1,
      leftEndSide: Side.a,
    );

MatchState play(MatchConfig c, List<Side> w) =>
    deriveMatch(c, [for (final s in w) PointEvent(s)]);

void main() {
  test('scoreCall puts the server first', () {
    final c = cfg(Format.singles);
    expect(scoreCall(play(c, [])), 'Love all');
    expect(scoreCall(play(c, [Side.a, Side.b])), '1 all');
    expect(scoreCall(play(c, [Side.a, Side.a, Side.b])), '1 – 2'); // B won the rally, so B serves
  });

  test('serveLine names server, court and receiver', () {
    final c = cfg(Format.doubles);
    expect(serveLine(c, play(c, [])), 'Ann serves from the right to Bob');
    expect(serveLine(c, play(c, [Side.a])), 'Ann serves from the left to Bea');
  });

  test('teamName', () {
    expect(teamName(cfg(Format.doubles), Side.a), 'Ann & Al');
    expect(teamName(cfg(Format.singles), Side.b), 'Bob');
  });

  test('cueLabel', () {
    final c = cfg(Format.doubles);
    expect(cueLabel(c, const ChangeEndsCue()), 'Change ends');
    expect(cueLabel(c, const IntervalCue(60)), 'Interval · 60 s');
    expect(cueLabel(c, const MatchPointCue(Side.b)), 'Match point · Bob & Bea');
    expect(cueLabel(c, const GamePointCue(Side.a)), 'Game point · Ann & Al');
    expect(cueLabel(c, const GameWonCue(Side.a)), isNull);
  });
}
