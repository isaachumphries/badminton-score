enum Side {
  a,
  b;

  Side get other => this == Side.a ? Side.b : Side.a;
}

enum PlayerId {
  a1,
  a2,
  b1,
  b2;

  Side get side => index < 2 ? Side.a : Side.b;

  PlayerId get partner => switch (this) {
        PlayerId.a1 => PlayerId.a2,
        PlayerId.a2 => PlayerId.a1,
        PlayerId.b1 => PlayerId.b2,
        PlayerId.b2 => PlayerId.b1,
      };
}

enum Court { right, left }

enum Format { singles, doubles }

class Ruleset {
  final String id;
  final String label;
  final int pointsToWin;
  final int cap;
  final int changeEndsAt;
  final int intervalAt;
  final int intervalSec;
  final int betweenGamesSec;
  final int gamesToWin;

  const Ruleset({
    required this.id,
    required this.label,
    required this.pointsToWin,
    required this.cap,
    required this.changeEndsAt,
    required this.intervalAt,
    required this.intervalSec,
    required this.betweenGamesSec,
    required this.gamesToWin,
  });
}
