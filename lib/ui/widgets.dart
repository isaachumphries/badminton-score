import 'package:flutter/material.dart';

import 'theme.dart';

/// Round team-coloured badge with a player's initials.
class PlayerMarker extends StatelessWidget {
  const PlayerMarker(
      {super.key, required this.initials, required this.color, this.size = 24, this.ring = false});
  final String initials;
  final Color color;
  final double size;
  final bool ring; // white outline, used on the court

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: ring ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(
          initials,
          maxLines: 1,
          style: sans(size * 0.4, weight: FontWeight.w600, color: Colors.white),
        ),
      );
}

/// Shuttlecock outline, the app's serve marker.
class ShuttleIcon extends StatelessWidget {
  const ShuttleIcon({super.key, this.size = 16, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.square(size), painter: _ShuttlePainter(color));
}

class _ShuttlePainter extends CustomPainter {
  _ShuttlePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / k
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(7, 3)
          ..lineTo(17, 3)
          ..lineTo(14, 14)
          ..lineTo(10, 14)
          ..close(),
        p);
    canvas.drawLine(const Offset(10.6, 3.2), const Offset(11.2, 14), p);
    canvas.drawLine(const Offset(13.4, 3.2), const Offset(12.8, 14), p);
    canvas.drawCircle(const Offset(12, 18), 3.5, p);
  }

  @override
  bool shouldRepaint(_ShuttlePainter old) => old.color != color;
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 8),
        child: Text(text,
            style: sans(13, weight: FontWeight.w500, color: secondary, lineHeight: 20)),
      );
}

/// Two-or-more option switch on an inset track.
class Segmented<T> extends StatelessWidget {
  const Segmented(
      {super.key, required this.options, required this.selected, required this.onChanged});
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: raised, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          for (final (value, label) in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: const Cubic(0.22, 1, 0.36, 1),
                  height: 32,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: value == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: value == selected
                        ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Text(label,
                      key: Key('segment-$label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sans(14,
                          weight: FontWeight.w500,
                          color: value == selected ? ink : secondary)),
                ),
              ),
            ),
        ]),
      );
}

/// Selectable player: marker, name, check when chosen.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile(
      {super.key,
      required this.initials,
      required this.color,
      required this.name,
      required this.selected,
      required this.onTap});
  final String initials, name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? Colors.white : card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? ink : hairline, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 12),
              child: Row(children: [
                PlayerMarker(initials: initials, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sans(15, weight: selected ? FontWeight.w500 : FontWeight.w400)),
                ),
                if (selected) const Icon(Icons.check_rounded, size: 18, color: ink),
              ]),
            ),
          ),
        ),
      );
}

class SmallSwitch extends StatelessWidget {
  const SmallSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: const Cubic(0.22, 1, 0.36, 1),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: value ? ink : const Color(0x2E1F1B16),
              borderRadius: BorderRadius.circular(13)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: const Cubic(0.22, 1, 0.36, 1),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ),
      );
}

/// Full-width near-black action. Disabled reads as an inset well.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key, required this.label, required this.onPressed, this.buttonKey});
  final String label;
  final VoidCallback? onPressed;
  final Key? buttonKey; // lands on the FilledButton itself

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          key: buttonKey,
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: card,
            disabledBackgroundColor: raised,
            disabledForegroundColor: muted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: sans(16, weight: FontWeight.w500),
          ),
          child: Text(label),
        ),
      );
}

BoxDecoration cardDecoration({double radius = 16, Color? border, double width = 1}) =>
    BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? hairline, width: width),
    );
