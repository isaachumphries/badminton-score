import 'dart:math';

import 'types.dart';

bool isGameWon(int a, int b, Ruleset r) {
  final hi = max(a, b);
  final lo = min(a, b);
  return hi == r.cap || (hi >= r.pointsToWin && hi - lo >= 2);
}

/// True if one more point for [scoreFor] ends the game.
bool wouldWinGame(int scoreFor, int scoreAgainst, Ruleset r) =>
    isGameWon(scoreFor + 1, scoreAgainst, r);
