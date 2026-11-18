import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/match_controller.dart';
import '../engine/match.dart';
import '../engine/types.dart';
import 'court_view.dart';
import 'labels.dart';
import 'theme.dart';
import 'widgets.dart';

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
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final s = controller.state;
          final playing = s.status == MatchStatus.playing;
          return Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _Header(
                      game: s.gameNumber,
                      meta: rulesetMeta(config.ruleset),
                      onClose: () => _confirmNew(context),
                    ),
                    Expanded(child: _panel(Side.a, s)),
                    _CourtSection(config: config, state: s),
                    Expanded(child: _panel(Side.b, s)),
                    _Footer(canUndo: controller.canUndo, onUndo: controller.undo),
                  ],
                ),
              ),
              if (!playing)
                Positioned.fill(
                  child: ColoredBox(
                    color: ink.withValues(alpha: 0.42),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _Sheet(
                        child: s.status == MatchStatus.finished
                            ? _FinishedSheet(
                                config: config, state: s, onNewMatch: onNewMatch)
                            : _NextGameSheet(
                                key: ValueKey(s.gameNumber),
                                config: config,
                                state: s,
                                onStart: (srv, rcv) =>
                                    controller.push(StartGameEvent(srv, rcv)),
                                onUndo: controller.undo,
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _panel(Side side, MatchState s) {
    final serving = s.status == MatchStatus.playing && s.rally.server.side == side;
    return _Panel(
      key: Key('panel-${side.name}'),
      side: side,
      name: teamName(config, side),
      score: s.rally.scores[side]!,
      gamesWon: s.gamesWon[side]!,
      gamesToWin: config.ruleset.gamesToWin,
      servingFrom: serving ? s.rally.positions[s.rally.server]!.name : null,
      onTap: () => _point(side),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.meta, required this.onClose});
  final int game;
  final String meta;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Game $game', style: sans(17, weight: FontWeight.w500, lineHeight: 22)),
                  const SizedBox(height: 2),
                  Text(meta, style: mono(12)),
                ],
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                key: const Key('menu'),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: raised,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.close_rounded, size: 18, color: secondary),
                tooltip: 'New match',
              ),
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
    required this.servingFrom,
    required this.onTap,
  });

  final Side side;
  final String name;
  final int score, gamesWon, gamesToWin;
  final String? servingFrom; // court the server stands in, when serving
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = teamColor(side);
    final serving = servingFrom != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: serving ? color.withValues(alpha: 0.55) : hairline,
            width: serving ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: sans(15, weight: FontWeight.w500, lineHeight: 20)),
                  ),
                  for (var i = 0; i < gamesToWin; i++)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < gamesWon ? color : null,
                        border: i < gamesWon
                            ? null
                            : Border.all(color: muted.withValues(alpha: 0.5), width: 1.5),
                      ),
                    ),
                ]),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      child: Text('$score',
                          key: Key('score-${side.name}'), style: figures(120)),
                    ),
                  ),
                ),
                SizedBox(
                  height: 16,
                  child: serving
                      ? Row(children: [
                          ShuttleIcon(size: 16, color: teamTextColor(side)),
                          const SizedBox(width: 8),
                          Text('Serving from the $servingFrom',
                              style: sans(13,
                                  weight: FontWeight.w500,
                                  color: teamTextColor(side),
                                  lineHeight: 16)),
                        ])
                      : null,
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CourtView(config: config, state: state),
          const SizedBox(height: 10),
          SizedBox(
            height: 20,
            child: playing
                ? Text.rich(
                    key: const Key('call'),
                    TextSpan(children: [
                      TextSpan(
                          text: scoreCall(state),
                          style: sans(13, weight: FontWeight.w500)),
                      TextSpan(
                          text: '  ·  ${serveLine(config, state)}',
                          style: sans(13, color: secondary)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  )
                : null,
          ),
          SizedBox(
            height: 32,
            child: Center(
              child: cues.isEmpty
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: ink, borderRadius: BorderRadius.circular(8)),
                      child: Text(cues.join('  ·  '),
                          style: sans(12, weight: FontWeight.w500, color: card)),
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
          style: TextButton.styleFrom(
            foregroundColor: secondary,
            disabledForegroundColor: muted.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.undo_rounded, size: 18),
          label: const Text('Undo'),
        ),
      );
}

/// Bottom sheet frame shared by the between-games and match-won views.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 16 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

String _takes(MatchConfig c) => c.format == Format.doubles ? 'take' : 'takes';

Widget _finalScore(int winner, int loser) => Row(children: [
      Text('$winner', style: figures(48)),
      const SizedBox(width: 12),
      Text('–', style: figures(48, color: muted)),
      const SizedBox(width: 12),
      Text('$loser', style: figures(48, color: muted)),
    ]);

class _NextGameSheet extends StatefulWidget {
  const _NextGameSheet(
      {super.key,
      required this.config,
      required this.state,
      required this.onStart,
      required this.onUndo});
  final MatchConfig config;
  final MatchState state;
  final void Function(PlayerId server, PlayerId receiver) onStart;
  final VoidCallback onUndo;

  @override
  State<_NextGameSheet> createState() => _NextGameSheetState();
}

class _NextGameSheetState extends State<_NextGameSheet> {
  late PlayerId server;
  late PlayerId receiver;

  @override
  void initState() {
    super.initState();
    final d = defaultNextServe(widget.state);
    server = d.server;
    receiver = d.receiver;
  }

  List<PlayerId> _of(Side s) => widget.config.format == Format.singles
      ? [s == Side.a ? PlayerId.a1 : PlayerId.b1]
      : (s == Side.a ? [PlayerId.a1, PlayerId.a2] : [PlayerId.b1, PlayerId.b2]);

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final games = widget.state.finishedGames;
    final last = games.last;
    final winner = last[Side.a]! > last[Side.b]! ? Side.a : Side.b;
    final n = games.length;
    return Column(
      key: const Key('next-game'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text('Game $n · final', style: mono(12))),
          GestureDetector(
            onTap: widget.onUndo,
            child: Text('Undo last point', style: sans(13, weight: FontWeight.w500, color: secondary)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('${teamName(c, winner)} ${_takes(c)} game $n',
            style: sans(22, weight: FontWeight.w500, lineHeight: 28)),
        const SizedBox(height: 8),
        _finalScore(last[winner]!, last[winner.other]!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: raised, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.swap_horiz_rounded, size: 18, color: secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Change ends before game ${n + 1}',
                  style: sans(14, color: secondary, lineHeight: 20)),
            ),
          ]),
        ),
        if (c.format == Format.doubles) ...[
          const SizedBox(height: 4),
          _pick('Serves', _of(winner), server, (p) => setState(() => server = p)),
          _pick('Receives', _of(winner.other), receiver,
              (p) => setState(() => receiver = p)),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          buttonKey: const Key('start-game'),
          label: 'Start game ${n + 1}',
          onPressed: () => widget.onStart(server, receiver),
        ),
      ],
    );
  }

  Widget _pick(String label, List<PlayerId> options, PlayerId selected,
          void Function(PlayerId) onPick) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          Row(children: [
            for (final p in options) ...[
              if (p != options.first) const SizedBox(width: 12),
              Expanded(
                child: ChoiceTile(
                  initials: playerInitials(widget.config, p),
                  color: teamColor(p.side),
                  name: playerName(widget.config, p),
                  selected: selected == p,
                  onTap: () => onPick(p),
                ),
              ),
            ],
          ]),
        ],
      );
}

class _FinishedSheet extends StatelessWidget {
  const _FinishedSheet(
      {required this.config, required this.state, required this.onNewMatch});
  final MatchConfig config;
  final MatchState state;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    final w = state.winner!;
    return Column(
      key: const Key('finished'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Match · final', style: mono(12)),
        const SizedBox(height: 4),
        Text('${teamName(config, w)} ${_takes(config)} the match',
            style: sans(22, weight: FontWeight.w500, lineHeight: 28)),
        const SizedBox(height: 16),
        Container(
          decoration: cardDecoration(radius: 12),
          child: Column(children: [
            for (final (i, g) in state.finishedGames.indexed) ...[
              if (i > 0) const Divider(height: 1, thickness: 1, color: hairline),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Expanded(child: Text('Game ${i + 1}', style: sans(15, color: secondary))),
                  Text('${g[w]} – ${g[w.other]}',
                      style: mono(15,
                          weight: FontWeight.w500,
                          color: g[w]! > g[w.other]! ? ink : muted)),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'New match', onPressed: onNewMatch),
      ],
    );
  }
}
