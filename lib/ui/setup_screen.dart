import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/match.dart';
import '../engine/rulesets.dart';
import '../engine/types.dart';
import 'theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onStart});
  final void Function(MatchConfig) onStart;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  Format format = Format.doubles;
  Ruleset? standard; // the user decides; nothing preselected
  bool custom = false;
  bool winBy2 = true;
  final _points = TextEditingController(text: '11');
  PlayerId server = PlayerId.a1;
  PlayerId receiver = PlayerId.b1;
  Side leftEnd = Side.a;

  static const _defaults = {
    PlayerId.a1: 'Player 1',
    PlayerId.a2: 'Player 2',
    PlayerId.b1: 'Player 3',
    PlayerId.b2: 'Player 4',
  };
  final _fields = {
    for (final p in PlayerId.values) p: TextEditingController(),
  };

  @override
  void dispose() {
    _points.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Ruleset? get ruleset {
    if (!custom) return standard;
    final n = int.tryParse(_points.text.trim());
    return n == null || n < 2 || n > 99 ? null : customRuleset(n, winBy2: winBy2);
  }

  String _name(PlayerId p) {
    final t = _fields[p]!.text.trim();
    return t.isEmpty ? _defaults[p]! : t;
  }

  List<PlayerId> get _players => format == Format.singles
      ? [PlayerId.a1, PlayerId.b1]
      : PlayerId.values;

  void _setServer(PlayerId p) => setState(() {
        server = p;
        if (receiver.side == server.side) {
          receiver = p.side == Side.a ? PlayerId.b1 : PlayerId.a1;
        }
      });

  void _setFormat(Format f) => setState(() {
        format = f;
        if (f == Format.singles) {
          server = server.side == Side.a ? PlayerId.a1 : PlayerId.b1;
          receiver = server.side == Side.a ? PlayerId.b1 : PlayerId.a1;
        }
      });

  void _start() {
    final r = ruleset;
    if (r == null) return;
    widget.onStart(MatchConfig(
      format: format,
      ruleset: r,
      names: {for (final p in PlayerId.values) p: _name(p)},
      firstServer: server,
      firstReceiver: receiver,
      leftEndSide: leftEnd,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                children: [
                  const Text('Badminton',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  const Text('New match', style: TextStyle(color: muted)),
                  _section('Format'),
                  SegmentedButton<Format>(
                    key: const Key('format'),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: Format.singles,
                          label: Text('Singles', key: Key('format-singles'))),
                      ButtonSegment(
                          value: Format.doubles,
                          label: Text('Doubles', key: Key('format-doubles'))),
                    ],
                    selected: {format},
                    onSelectionChanged: (s) => _setFormat(s.first),
                  ),
                  _section('Scoring'),
                  for (final r in allRulesets) _RulesetTile(
                    key: Key('ruleset-${r.id}'),
                    ruleset: r,
                    selected: !custom && standard?.id == r.id,
                    onTap: () => setState(() {
                      custom = false;
                      standard = r;
                    }),
                  ),
                  _CustomTile(
                    selected: custom,
                    points: _points,
                    winBy2: winBy2,
                    onSelect: () => setState(() => custom = true),
                    onChanged: () => setState(() {}),
                    onWinBy2: (v) => setState(() => winBy2 = v),
                  ),
                  _section('Players'),
                  for (final side in Side.values) ...[
                    Row(
                      children: [
                        for (final p in _players.where((p) => p.side == side))
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: format == Format.doubles ? 8 : 0,
                                  bottom: 8),
                              child: TextField(
                                controller: _fields[p],
                                onChanged: (_) => setState(() {}),
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: _defaults[p],
                                  prefixIcon: Icon(Icons.circle,
                                      size: 12, color: teamColor(side)),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  _section('First serve'),
                  Wrap(spacing: 8, children: [
                    for (final p in _players)
                      ChoiceChip(
                        label: Text(_name(p)),
                        selected: server == p,
                        onSelected: (_) => _setServer(p),
                      ),
                  ]),
                  if (format == Format.doubles) ...[
                    _section('First receive'),
                    Wrap(spacing: 8, children: [
                      for (final p in _players.where((p) => p.side != server.side))
                        ChoiceChip(
                          label: Text(_name(p)),
                          selected: receiver == p,
                          onSelected: (_) => setState(() => receiver = p),
                        ),
                    ]),
                  ],
                  _section('Left end of the court'),
                  SegmentedButton<Side>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: Side.a, label: Text(_name(PlayerId.a1))),
                      ButtonSegment(
                          value: Side.b, label: Text(_name(PlayerId.b1))),
                    ],
                    selected: {leftEnd},
                    onSelectionChanged: (s) => setState(() => leftEnd = s.first),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  key: const Key('start'),
                  onPressed: ruleset == null ? null : _start,
                  child: Text(
                      ruleset == null ? 'Choose a scoring system' : 'Start match',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: muted)),
      );
}

class _CustomTile extends StatelessWidget {
  const _CustomTile({
    required this.selected,
    required this.points,
    required this.winBy2,
    required this.onSelect,
    required this.onChanged,
    required this.onWinBy2,
  });
  final bool selected, winBy2;
  final TextEditingController points;
  final VoidCallback onSelect, onChanged;
  final ValueChanged<bool> onWinBy2;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          key: const Key('ruleset-custom'),
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? teamAColor : courtLine,
                  width: selected ? 2 : 1),
              color: selected ? teamAColor.withValues(alpha: 0.07) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Custom points',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const Text('Best of 3 to any target, e.g. 5, 11, 50',
                    style: TextStyle(color: muted, fontSize: 12)),
                if (selected) ...[
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('custom-points'),
                    controller: points,
                    onChanged: (_) => onChanged(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Points to win (2–99)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Win by 2'),
                    value: winBy2,
                    onChanged: onWinBy2,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _RulesetTile extends StatelessWidget {
  const _RulesetTile(
      {super.key,
      required this.ruleset,
      required this.selected,
      required this.onTap});
  final Ruleset ruleset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? teamAColor : courtLine,
                  width: selected ? 2 : 1),
              color: selected ? teamAColor.withValues(alpha: 0.07) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ruleset.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(
                          'Best of ${ruleset.gamesToWin * 2 - 1} · '
                          'change ends at ${ruleset.changeEndsAt} in game 3',
                          style: const TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: teamAColor),
              ],
            ),
          ),
        ),
      );
}
