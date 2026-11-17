import 'package:flutter/material.dart';

import '../engine/match.dart';
import '../engine/types.dart';
import 'labels.dart';
import 'theme.dart';

/// Top-down court. The team on the left end is drawn on the left; "right" and
/// "left" courts are from each team's own point of view (facing the net).
class CourtView extends StatelessWidget {
  const CourtView({super.key, required this.config, required this.state});

  final MatchConfig config;
  final MatchState state;

  @override
  Widget build(BuildContext context) {
    final leftSide = state.leftEndSide;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _EndLabel(config, leftSide, TextAlign.left),
            _EndLabel(config, leftSide.other, TextAlign.right),
          ],
        ),
        const SizedBox(height: 6),
        AspectRatio(
          key: const Key('court'),
          aspectRatio: 13.4 / 6.1,
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: _CourtPainter())),
                for (final entry in state.rally.positions.entries)
                  _place(entry.key, entry.value, leftSide, w, h),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _place(PlayerId p, Court court, Side leftSide, double w, double h) {
    final onLeftEnd = p.side == leftSide;
    // Facing the net, a left-end team's right hand points down the screen.
    final bottom = onLeftEnd ? court == Court.right : court == Court.left;
    final fx = onLeftEnd ? 0.27 : 0.73;
    final fy = bottom ? 0.75 : 0.25;
    final role = p == state.rally.server
        ? 'serves'
        : p == state.rally.receiver
            ? 'receives'
            : null;
    return Positioned(
      left: fx * w,
      top: fy * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: _Chip(
          name: playerName(config, p),
          color: teamColor(p.side),
          role: role,
          labelAbove: bottom,
        ),
      ),
    );
  }
}

class _EndLabel extends StatelessWidget {
  const _EndLabel(this.config, this.side, this.align);
  final MatchConfig config;
  final Side side;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(
          teamName(config, side),
          textAlign: align,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: teamColor(side),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.name,
      required this.color,
      this.role,
      this.labelAbove = false});
  final String name;
  final Color color;
  final String? role;
  final bool labelAbove; // bottom-row players: label goes above to stay on court

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: role == null
                  ? null
                  : Border.all(color: ink, width: role == 'serves' ? 3 : 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (role != null)
            Positioned(
              top: labelAbove ? -16 : 43,
              left: -20,
              right: -20,
              child: Text(
                role!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10, color: muted, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    double x(double m) => m / 13.4 * w;
    double y(double m) => m / 6.1 * h;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      Paint()..color = courtFill,
    );
    final line = Paint()
      ..color = courtLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(Rect.fromLTRB(1, 1, w - 1, h - 1), line);
    for (final m in [0.46, 6.1 - 0.46]) {
      canvas.drawLine(Offset(0, y(m)), Offset(w, y(m)), line);
    }
    for (final m in [6.7 - 1.98, 6.7 + 1.98, 0.76, 13.4 - 0.76]) {
      canvas.drawLine(Offset(x(m), 0), Offset(x(m), h), line);
    }
    canvas.drawLine(Offset(0, y(3.05)), Offset(x(6.7 - 1.98), y(3.05)), line);
    canvas.drawLine(Offset(x(6.7 + 1.98), y(3.05)), Offset(w, y(3.05)), line);
    canvas.drawLine(
      Offset(w / 2, -4),
      Offset(w / 2, h + 4),
      Paint()
        ..color = ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CourtPainter old) => false;
}
