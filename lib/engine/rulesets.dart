import 'types.dart';

const Ruleset bwf21 = Ruleset(
  id: 'bwf21',
  label: '21 points (cap 30)',
  pointsToWin: 21,
  cap: 30,
  changeEndsAt: 11,
  intervalAt: 11,
  intervalSec: 60,
  betweenGamesSec: 120,
  gamesToWin: 2,
);

const Ruleset bwf15 = Ruleset(
  id: 'bwf15',
  label: '15 points (cap 21)',
  pointsToWin: 15,
  cap: 21,
  changeEndsAt: 8,
  intervalAt: 8,
  intervalSec: 60,
  betweenGamesSec: 120,
  gamesToWin: 2,
);

const List<Ruleset> allRulesets = [bwf21, bwf15];

/// Best of 3 to [points]; changes ends/interval at the halfway point.
Ruleset customRuleset(int points, {required bool winBy2}) => Ruleset(
      id: 'custom',
      label: 'Custom: $points points${winBy2 ? ' (win by 2)' : ''}',
      pointsToWin: points,
      cap: winBy2 ? points + 9 : points,
      changeEndsAt: (points + 1) ~/ 2,
      intervalAt: (points + 1) ~/ 2,
      intervalSec: 60,
      betweenGamesSec: 120,
      gamesToWin: 2,
    );
