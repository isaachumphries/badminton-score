import 'types.dart';

class Rally {
  final Map<Side, int> scores;
  final PlayerId server;
  final PlayerId receiver;

  /// Court of every on-court player (singles: only server and receiver).
  final Map<PlayerId, Court> positions;

  const Rally({
    required this.scores,
    required this.server,
    required this.receiver,
    required this.positions,
  });
}

Rally startRally(Format f, PlayerId server, PlayerId receiver) {
  final positions = <PlayerId, Court>{
    server: Court.right,
    receiver: Court.right,
  };
  if (f == Format.doubles) {
    positions[server.partner] = Court.left;
    positions[receiver.partner] = Court.left;
  }
  return Rally(
    scores: {Side.a: 0, Side.b: 0},
    server: server,
    receiver: receiver,
    positions: positions,
  );
}

Rally awardPoint(Rally r, Side winner, Format f) {
  final scores = {...r.scores, winner: r.scores[winner]! + 1};
  final newScore = scores[winner]!;
  final positions = {...r.positions};
  PlayerId server;
  PlayerId receiver;

  if (f == Format.singles) {
    server = r.server.side == winner ? r.server : r.receiver;
    receiver = server == r.server ? r.receiver : r.server;
    final court = newScore.isEven ? Court.right : Court.left;
    positions[server] = court;
    positions[receiver] = court;
  } else {
    if (winner == r.server.side) {
      server = r.server;
      final a = positions[server]!;
      positions[server] = positions[server.partner]!;
      positions[server.partner] = a;
    } else {
      final court = newScore.isEven ? Court.right : Court.left;
      server = positions.keys
          .firstWhere((p) => p.side == winner && positions[p] == court);
    }
    receiver = positions.keys.firstWhere(
        (p) => p.side != server.side && positions[p] == positions[server]);
  }
  return Rally(
      scores: scores, server: server, receiver: receiver, positions: positions);
}
