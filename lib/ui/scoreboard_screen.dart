import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/match_controller.dart';
import '../engine/match.dart';
import '../engine/types.dart';
import 'court_view.dart';
import 'labels.dart';
import 'theme.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen(
      {super.key, required this.controller, required this.onNewMatch});

  final MatchController controller;
  final VoidCallback onNewMatch;

  MatchConfig get config => controller.config;

  void _point(Side side) {
    if (controller.push(PointEvent(side))) {
      controller.state.cues.isEmpty
          ? HapticFeedback.lightImpact()
          : HapticFeedback.mediumImpact();
    }
  }

  Future<void> _confirmNew(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Start a new match?'),
        content: const Text('The current match will be discarded.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('New match')),
        ],
      ),
    );
    if (ok == true) onNewMatch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final s = controller.state;
            final playing = s.status == MatchStatus.playing;
            return Column(
              children: [
                _Header(
                  title: 'Game ${s.gameNumber} · ${config.ruleset.label}',
                  onMenu: () => _confirmNew(context),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(child: _panel(Side.a, s)),
                          _CourtSection(config: config, state: s),
                          Expanded(child: _panel(Side.b, s)),
                        ],
                      ),
                      if (!playing)
                        Positioned.fill(
                          child: ColoredBox(
                            color: paper.withValues(alpha: 0.92),
                            child: Center(
                              child: s.status == MatchStatus.finished
                                  ? _FinishedCard(
                                      config: config,
                                      state: s,
                                      onNewMatch: onNewMatch)
                                  : _NextGameCard(
                                      key: ValueKey(s.gameNumber),
                                      config: config,
                                      state: s,
                                      onStart: (srv, rcv) => controller
                                          .push(StartGameEvent(srv, rcv)),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _Footer(
                  canUndo: controller.canUndo,
                  onUndo: controller.undo,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _panel(Side side, MatchState s) => _Panel(
        key: Key('panel-${side.name}'),
        side: side,
        name: teamName(config, side),
        score: s.rally.scores[side]!,
        gamesWon: s.gamesWon[side]!,
        gamesToWin: config.ruleset.gamesToWin,
        serving: s.status == MatchStatus.playing && s.rally.server.side == side,
        onTap: () => _point(side),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onMenu});
  final String title;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              key: const Key('menu'),
              onPressed: onMenu,
              icon: const Icon(Icons.close, color: muted),
              tooltip: 'New match',
            ),
          ],
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.side,
    required this.name,
    required this.score,
    required this.gamesWon,
    required this.gamesToWin,
    required this.serving,
    required this.onTap,
  });

  final Side side;
  final String name;
  final int score, gamesWon, gamesToWin;
  final bool serving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = teamColor(side);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 18,
                top: 14,
                right: 100,
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: color, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: Row(children: [
                  for (var i = 0; i < gamesToWin; i++)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < gamesWon ? color : Colors.transparent,
                        border: Border.all(color: color, width: 1.5),
                      ),
                    ),
                ]),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: FittedBox(
                    child: Text(
                      '$score',
                      key: Key('score-${side.name}'),
                      style: TextStyle(
                        color: ink,
                        fontSize: 120,
                        height: 1,
                        fontWeight: FontWeight.w300,
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                ),
              ),
              if (serving)
                Positioned(
                  left: 18,
                  bottom: 14,
                  child: Row(children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 6),
                    Text('SERVING',
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtSection extends StatelessWidget {
  const _CourtSection({required this.config, required this.state});
  final MatchConfig config;
  final MatchState state;

  @override
  Widget build(BuildContext context) {
    final cues = [
      for (final c in state.cues)
        if (cueLabel(config, c) != null) cueLabel(config, c)!
    ];
    final playing = state.status == MatchStatus.playing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CourtView(config: config, state: state),
          const SizedBox(height: 10),
          if (playing) ...[
            Text(scoreCall(state),
                key: const Key('call'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(serveLine(config, state),
                style: const TextStyle(color: muted, fontSize: 13)),
          ],
          SizedBox(
            height: 34,
            child: Center(
              child: cues.isEmpty
                  ? null
                  : Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: ink, borderRadius: BorderRadius.circular(20)),
                      child: Text(cues.join('  ·  '),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.canUndo, required this.onUndo});
  final bool canUndo;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: TextButton.icon(
          key: const Key('undo'),
          onPressed: canUndo ? onUndo : null,
          icon: const Icon(Icons.undo),
          label: const Text('Undo'),
        ),
      );
}

class _NextGameCard extends StatefulWidget {
  const _NextGameCard(
      {super.key,
      required this.config,
      required this.state,
      required this.onStart});
  final MatchConfig config;
  final MatchState state;
  final void Function(PlayerId server, PlayerId receiver) onStart;

  @override
  State<_NextGameCard> createState() => _NextGameCardState();
}

class _NextGameCardState extends State<_NextGameCard> {
  late PlayerId server;
  late PlayerId receiver;

  @override
  void initState() {
    super.initState();
    final d = defaultNextServe(widget.config, widget.state);
    server = d.server;
    receiver = d.receiver;
  }

  List<PlayerId> _of(Side s) => widget.config.format == Format.singles
      ? [s == Side.a ? PlayerId.a1 : PlayerId.b1]
      : (s == Side.a
          ? [PlayerId.a1, PlayerId.a2]
          : [PlayerId.b1, PlayerId.b2]);

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final games = widget.state.finishedGames;
    final last = games.last;
    final winner = last[Side.a]! > last[Side.b]! ? Side.a : Side.b;
    final doubles = c.format == Format.doubles;
    return Card(
      key: const Key('next-game'),
      margin: const EdgeInsets.all(24),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Game ${games.length}',
                style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(teamName(c, winner),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: teamColor(winner),
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            Text('${last[Side.a]} – ${last[Side.b]}',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    fontFeatures: tabular)),
            const SizedBox(height: 4),
            const Text('Change ends', style: TextStyle(color: muted)),
            if (doubles) ...[
              const SizedBox(height: 16),
              _pick('Serves', _of(winner), server,
                  (p) => setState(() => server = p)),
              _pick('Receives', _of(winner.other), receiver,
                  (p) => setState(() => receiver = p)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                key: const Key('start-game'),
                onPressed: () => widget.onStart(server, receiver),
                child: Text('Start game ${games.length + 1}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pick(String label, List<PlayerId> options, PlayerId selected,
          void Function(PlayerId) onPick) =>
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: muted, fontSize: 12)),
            Wrap(spacing: 8, children: [
              for (final p in options)
                ChoiceChip(
                  label: Text(playerName(widget.config, p)),
                  selected: selected == p,
                  onSelected: (_) => onPick(p),
                ),
            ]),
          ],
        ),
      );
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard(
      {required this.config, required this.state, required this.onNewMatch});
  final MatchConfig config;
  final MatchState state;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    final w = state.winner!;
    return Card(
      key: const Key('finished'),
      margin: const EdgeInsets.all(24),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Match won',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(teamName(config, w),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: teamColor(w),
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final g in state.finishedGames)
              Text('${g[Side.a]} – ${g[Side.b]}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      fontFeatures: tabular)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                  onPressed: onNewMatch, child: const Text('New match')),
            ),
          ],
        ),
      ),
    );
  }
}
