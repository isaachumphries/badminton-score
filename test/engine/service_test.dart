import 'dart:math';

import 'package:badminton_score/engine/service.dart';
import 'package:badminton_score/engine/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('doubles walkthrough', () {
    var r = startRally(Format.doubles, PlayerId.a1, PlayerId.b1);
    expect(r.positions, {
      PlayerId.a1: Court.right,
      PlayerId.a2: Court.left,
      PlayerId.b1: Court.right,
      PlayerId.b2: Court.left,
    });
    expect(r.scores, {Side.a: 0, Side.b: 0});

    r = awardPoint(r, Side.a, Format.doubles);
    expect(r.scores, {Side.a: 1, Side.b: 0});
    expect(r.server, PlayerId.a1);
    expect(r.positions[PlayerId.a1], Court.left);
    expect(r.positions[PlayerId.a2], Court.right);
    expect(r.receiver, PlayerId.b2);
    expect(r.positions[PlayerId.b1], Court.right);
    expect(r.positions[PlayerId.b2], Court.left);

    r = awardPoint(r, Side.b, Format.doubles);
    expect(r.scores, {Side.a: 1, Side.b: 1});
    expect(r.server, PlayerId.b2);
    expect(r.receiver, PlayerId.a1);
    expect(r.positions[PlayerId.a1], Court.left);
    expect(r.positions[PlayerId.b2], Court.left);

    r = awardPoint(r, Side.b, Format.doubles);
    expect(r.scores, {Side.a: 1, Side.b: 2});
    expect(r.server, PlayerId.b2);
    expect(r.positions[PlayerId.b2], Court.right);
    expect(r.positions[PlayerId.b1], Court.left);
    expect(r.receiver, PlayerId.a2);
  });

  test('singles walkthrough', () {
    var r = startRally(Format.singles, PlayerId.a1, PlayerId.b1);
    r = awardPoint(r, Side.a, Format.singles);
    expect(r.server, PlayerId.a1);
    expect(r.positions[PlayerId.a1], Court.left);
    expect(r.receiver, PlayerId.b1);
    expect(r.positions[PlayerId.b1], Court.left);

    r = awardPoint(r, Side.b, Format.singles);
    expect(r.scores[Side.b], 1);
    expect(r.server, PlayerId.b1);
    expect(r.positions[PlayerId.b1], Court.left);
    expect(r.receiver, PlayerId.a1);
    expect(r.positions[PlayerId.a1], Court.left);

    r = awardPoint(r, Side.b, Format.singles);
    expect(r.scores[Side.b], 2);
    expect(r.server, PlayerId.b1);
    expect(r.positions[PlayerId.b1], Court.right);
    expect(r.receiver, PlayerId.a1);
    expect(r.positions[PlayerId.a1], Court.right);
  });

  test('doubles invariants hold over random rallies', () {
    final rng = Random(42);
    for (var seq = 0; seq < 200; seq++) {
      var r = startRally(Format.doubles, PlayerId.a1, PlayerId.b1);
      final n = rng.nextInt(60) + 1;
      for (var i = 0; i < n; i++) {
        r = awardPoint(r, rng.nextBool() ? Side.a : Side.b, Format.doubles);
        final even = r.scores[r.server.side]!.isEven;
        expect(r.positions[r.server], even ? Court.right : Court.left);
        expect(r.receiver.side, r.server.side.other);
        expect(r.positions[r.receiver], r.positions[r.server]);
        for (final p in [PlayerId.a1, PlayerId.b1]) {
          expect(r.positions[p], isNot(r.positions[p.partner]));
        }
      }
    }
  });
}
