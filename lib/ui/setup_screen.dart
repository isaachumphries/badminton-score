import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/match.dart';
import '../engine/rulesets.dart';
import '../engine/types.dart';
import 'labels.dart';
import 'theme.dart';
import 'widgets.dart';

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

  /// Initials for [p] as they will appear on the court.
  String _initials(PlayerId p) {
    if (format == Format.singles) return teammateInitials(_name(p), '').$1;
    final lead = p.side == Side.a ? PlayerId.a1 : PlayerId.b1;
    final (one, two) = teammateInitials(_name(lead), _name(lead.partner));
    return p == lead ? one : two;
  }

  String _team(Side side) =>
      _players.where((p) => p.side == side).map(_name).join(' & ');

  void _setPoints(int n) => setState(() {
        _points.text = '${n.clamp(2, 99)}';
      });

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
    final r = ruleset;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                children: [
                  Text('Badminton', style: sans(30, weight: FontWeight.w500, lineHeight: 36)),
                  const SizedBox(height: 4),
                  Text('New match', style: sans(15, color: secondary, lineHeight: 20)),
                  const SectionLabel('Format'),
                  Segmented<Format>(
                    key: const Key('format'),
                    options: const [(Format.singles, 'Singles'), (Format.doubles, 'Doubles')],
                    selected: format,
                    onChanged: _setFormat,
                  ),
                  const SectionLabel('Scoring'),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: cardDecoration(),
                    child: Column(children: [
                      for (final rs in allRulesets) ...[
                        _OptionRow(
                          key: Key('ruleset-${rs.id}'),
                          title: '${rs.pointsToWin} points',
                          meta: 'cap ${rs.cap}',
                          subtitle: 'Best of ${rs.gamesToWin * 2 - 1} · '
                              'change ends at ${rs.changeEndsAt} in game 3',
                          selected: !custom && standard?.id == rs.id,
                          onTap: () => setState(() {
                            custom = false;
                            standard = rs;
                          }),
                        ),
                        const Divider(height: 1, thickness: 1, color: hairline),
                      ],
                      _OptionRow(
                        key: const Key('ruleset-custom'),
                        title: 'Custom',
                        subtitle: 'Best of 3 to any target',
                        selected: custom,
                        onTap: () => setState(() => custom = true),
                      ),
                      if (custom) _customSettings(),
                    ]),
                  ),
                  const SectionLabel('Players'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final side in Side.values) ...[
                        if (side == Side.b) const SizedBox(width: 12),
                        Expanded(
                          child: Column(children: [
                            for (final p in _players.where((p) => p.side == side))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _PlayerField(
                                  controller: _fields[p]!,
                                  hint: _defaults[p]!,
                                  initials: _initials(p),
                                  color: teamColor(side),
                                  onChanged: () => setState(() {}),
                                ),
                              ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                  const SectionLabel('First serve'),
                  _grid([
                    for (final p in _players)
                      _choice(p, server == p, () => _setServer(p)),
                  ]),
                  if (format == Format.doubles) ...[
                    const SectionLabel('First receive'),
                    _grid([
                      for (final p in _players.where((p) => p.side != server.side))
                        _choice(p, receiver == p, () => setState(() => receiver = p)),
                    ]),
                  ],
                  const SectionLabel('Left end of the court'),
                  Segmented<Side>(
                    options: [(Side.a, _team(Side.a)), (Side.b, _team(Side.b))],
                    selected: leftEnd,
                    onChanged: (s) => setState(() => leftEnd = s),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: paper,
                border: Border(top: BorderSide(color: hairline)),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
              child: PrimaryButton(
                buttonKey: const Key('start'),
                label: r == null ? 'Choose a scoring system' : 'Start match',
                onPressed: r == null ? null : _start,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(PlayerId p, bool selected, VoidCallback onTap) => ChoiceTile(
        initials: _initials(p),
        color: teamColor(p.side),
        name: _name(p),
        selected: selected,
        onTap: onTap,
      );

  /// Two tiles per row.
  Widget _grid(List<Widget> tiles) => Column(children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 8 : 0),
            child: Row(children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 12),
              Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
            ]),
          ),
      ]);

  Widget _customSettings() {
    final n = int.tryParse(_points.text.trim());
    Widget stepButton(IconData icon, int? to) => SizedBox(
          width: 36,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16,
            color: secondary,
            onPressed: to == null ? null : () => _setPoints(to),
            icon: Icon(icon),
          ),
        );
    return Container(
      color: raised.withValues(alpha: 0.45),
      child: Column(children: [
        const Divider(height: 1, thickness: 1, color: hairline),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            Expanded(child: Text('Points to win', style: sans(15, lineHeight: 20))),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hairline),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                stepButton(Icons.remove_rounded, n == null ? 11 : (n > 2 ? n - 1 : null)),
                SizedBox(
                  width: 36,
                  child: TextField(
                    key: const Key('custom-points'),
                    controller: _points,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    style: mono(15, weight: FontWeight.w500, color: ink),
                    decoration: const InputDecoration.collapsed(hintText: ''),
                  ),
                ),
                stepButton(Icons.add_rounded, n == null ? 11 : (n < 99 ? n + 1 : null)),
              ]),
            ),
          ]),
        ),
        const Divider(height: 1, thickness: 1, color: hairline),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
          child: Row(children: [
            Expanded(child: Text('Win by 2', style: sans(15, lineHeight: 20))),
            SmallSwitch(value: winBy2, onChanged: (v) => setState(() => winBy2 = v)),
          ]),
        ),
        if (n == null || n < 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pick a target from 2 to 99',
                  style: sans(13, color: teamBText)),
            ),
          ),
      ]),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.title,
    this.meta,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle;
  final String? meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(title, style: sans(15, weight: FontWeight.w500, lineHeight: 20)),
                      if (meta != null) ...[
                        const SizedBox(width: 8),
                        Text(meta!, style: mono(12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: sans(13, color: secondary, lineHeight: 18)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? ink : Colors.transparent,
                border: selected ? null : Border.all(color: muted.withValues(alpha: 0.5), width: 1.5),
              ),
              child: selected
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                  : null,
            ),
          ]),
        ),
      );
}

class _PlayerField extends StatelessWidget {
  const _PlayerField({
    required this.controller,
    required this.hint,
    required this.initials,
    required this.color,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint, initials;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.only(left: 10, right: 12),
        decoration: cardDecoration(radius: 10),
        child: Row(children: [
          PlayerMarker(initials: initials, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textCapitalization: TextCapitalization.words,
              style: sans(15),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: sans(15, color: muted),
              ),
            ),
          ),
        ]),
      );
}
