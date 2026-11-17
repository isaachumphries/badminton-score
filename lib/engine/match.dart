import 'dart:math';

import 'game.dart';
import 'service.dart';
import 'types.dart';

class MatchConfig {
  final Format format;
  final Ruleset ruleset;
  final Map<PlayerId, String> names;
  final PlayerId firstServer;
  final PlayerId firstReceiver;

  /// Side starting on the left end in game 1.
  final Side leftEndSide;

  const MatchConfig({
    required this.format,
    required this.ruleset,
    required this.names,
    required this.firstServer,
    required this.firstReceiver,
    required this.leftEndSide,
  });
}

sealed class MatchEvent {
  const MatchEvent();
}

class PointEvent extends MatchEvent {
  final Side winner;
  const PointEvent(this.winner);
}

class StartGameEvent extends MatchEvent {
  final PlayerId server;
  final PlayerId receiver;
  const StartGameEvent(this.server, this.receiver);
}

sealed class Cue {
  const Cue();
}

class GamePointCue extends Cue {
  final Side side;
  const GamePointCue(this.side);
  @override
  bool operator ==(Object other) => other is GamePointCue && other.side == side;
  @override
  int get hashCode => Object.hash('gp', side);
}

class MatchPointCue extends Cue {
  final Side side;
  const MatchPointCue(this.side);
  @override
  bool operator ==(Object other) => other is MatchPointCue && other.side == side;
  @override
  int get hashCode => Object.hash('mp', side);
}

class ChangeEndsCue extends Cue {
  const ChangeEndsCue();
  @override
  bool operator ==(Object other) => other is ChangeEndsCue;
  @override
  int get hashCode => 7;
}

class IntervalCue extends Cue {
  final int seconds;
  const IntervalCue(this.seconds);
  @override
  bool operator ==(Object other) => other is IntervalCue && other.seconds == seconds;
  @override
  int get hashCode => Object.hash('iv', seconds);
}

class GameWonCue extends Cue {
  final Side side;
  const GameWonCue(this.side);
  @override
  bool operator ==(Object other) => other is GameWonCue && other.side == side;
  @override
  int get hashCode => Object.hash('gw', side);
}

class MatchWonCue extends Cue {
  final Side side;
  const MatchWonCue(this.side);
  @override
  bool operator ==(Object other) => other is MatchWonCue && other.side == side;
  @override
  int get hashCode => Object.hash('mw', side);
}

enum MatchStatus { playing, betweenGames, finished }

class MatchState {
  final MatchStatus status;
  final int gameNumber;
  final Rally rally;
  final List<Map<Side, int>> finishedGames;
  final Map<Side, int> gamesWon;
  final Side leftEndSide;
  final List<Cue> cues;
  final Side? winner;
  final bool intervalFired;
  final bool endsChanged;

  const MatchState._({
    required this.status,
    required this.gameNumber,
    required this.rally,
    required this.finishedGames,
    required this.gamesWon,
    required this.leftEndSide,
    required this.cues,
    required this.winner,
    required this.intervalFired,
    required this.endsChanged,
  });
}

MatchState _initial(MatchConfig c) => MatchState._(
      status: MatchStatus.playing,
      gameNumber: 1,
      rally: startRally(c.format, c.firstServer, c.firstReceiver),
      finishedGames: const [],
      gamesWon: const {Side.a: 0, Side.b: 0},
      leftEndSide: c.leftEndSide,
      cues: const [],
      winner: null,
      intervalFired: false,
      endsChanged: false,
    );

/// Returns null if [e] is not valid in state [s].
MatchState? _apply(MatchConfig c, MatchState s, MatchEvent e) {
  final r = c.ruleset;
  switch (e) {
    case PointEvent():
      if (s.status != MatchStatus.playing) return null;
      final rally = awardPoint(s.rally, e.winner, c.format);
      final a = rally.scores[Side.a]!;
      final b = rally.scores[Side.b]!;
      final cues = <Cue>[];
      var left = s.leftEndSide;
      var intervalFired = s.intervalFired;
      var endsChanged = s.endsChanged;

      if (isGameWon(a, b, r)) {
        final gamesWon = {...s.gamesWon, e.winner: s.gamesWon[e.winner]! + 1};
        cues.add(GameWonCue(e.winner));
        final matchOver = gamesWon[e.winner]! >= r.gamesToWin;
        if (matchOver) cues.add(MatchWonCue(e.winner));
        return MatchState._(
          status: matchOver ? MatchStatus.finished : MatchStatus.betweenGames,
          gameNumber: s.gameNumber,
          rally: rally,
          finishedGames: [
            ...s.finishedGames,
            {Side.a: a, Side.b: b}
          ],
          gamesWon: gamesWon,
          leftEndSide: left,
          cues: cues,
          winner: matchOver ? e.winner : null,
          intervalFired: intervalFired,
          endsChanged: endsChanged,
        );
      }

      final hi = max(a, b);
      if (!intervalFired && hi >= r.intervalAt) {
        cues.add(IntervalCue(r.intervalSec));
        intervalFired = true;
      }
      final decider = s.gameNumber == r.gamesToWin * 2 - 1;
      if (decider && !endsChanged && hi >= r.changeEndsAt) {
        cues.add(const ChangeEndsCue());
        left = left.other;
        endsChanged = true;
      }
      for (final side in Side.values) {
        final mine = rally.scores[side]!;
        final theirs = rally.scores[side.other]!;
        if (wouldWinGame(mine, theirs, r)) {
          cues.add(s.gamesWon[side]! + 1 >= r.gamesToWin
              ? MatchPointCue(side)
              : GamePointCue(side));
        }
      }
      return MatchState._(
        status: MatchStatus.playing,
        gameNumber: s.gameNumber,
        rally: rally,
        finishedGames: s.finishedGames,
        gamesWon: s.gamesWon,
        leftEndSide: left,
        cues: cues,
        winner: null,
        intervalFired: intervalFired,
        endsChanged: endsChanged,
      );
    case StartGameEvent():
      if (s.status != MatchStatus.betweenGames) return null;
      if (e.server.side == e.receiver.side) return null;
      return MatchState._(
        status: MatchStatus.playing,
        gameNumber: s.gameNumber + 1,
        rally: startRally(c.format, e.server, e.receiver),
        finishedGames: s.finishedGames,
        gamesWon: s.gamesWon,
        leftEndSide: s.leftEndSide.other,
        cues: const [],
        winner: null,
        intervalFired: false,
        endsChanged: false,
      );
  }
}

/// Replays [events]; events invalid at their point in the log are skipped.
MatchState deriveMatch(MatchConfig c, List<MatchEvent> events) {
  var s = _initial(c);
  for (final e in events) {
    s = _apply(c, s, e) ?? s;
  }
  return s;
}

bool canAcceptEvent(MatchConfig c, List<MatchEvent> events, MatchEvent e) =>
    _apply(c, deriveMatch(c, events), e) != null;

/// Previous game's winner serves, using the player who served the last rally.
({PlayerId server, PlayerId receiver}) defaultNextServe(MatchState s) =>
    (server: s.rally.server, receiver: s.rally.receiver);
