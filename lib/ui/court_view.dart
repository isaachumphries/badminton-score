import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../engine/match.dart';
import '../engine/types.dart';
import 'labels.dart';
import 'theme.dart';
import 'widgets.dart';

/// Top-down court. The team on the left end is drawn on the left; "right" and
/// "left" courts are from each team's own point of view (facing the net).
/// A dashed line runs from the server to the receiver.
class CourtView extends StatelessWidget {
  const CourtView({super.key, required this.config, required this.state});

  final MatchConfig config;
  final MatchState state;

  static const _inset = 12.0;
  static const _marker = 32.0;

  @override
  Widget build(BuildContext context) {
    final leftSide = state.leftEndSide;
    final playing = state.status == MatchStatus.playing;
    return Container(
      decoration: BoxDecoration(
        color: courtFill,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(_inset),
      child: AspectRatio(
        key: const Key('court'),
        aspectRatio: 13.4 / 6.1,
        child: LayoutBuilder(builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          Offset at(PlayerId p) =>
              _spot(p, state.rally.positions[p]!, leftSide, size);
          final server = state.rally.server, receiver = state.rally.receiver;
          final serverAt = at(server);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CourtPainter(
                    serve: playing ? (at(server), at(receiver)) : null,
                  ),
                ),
              ),
              for (final p in state.rally.positions.keys)
                Positioned(
                  left: at(p).dx - _marker / 2,
                  top: at(p).dy - _marker / 2,
                  child: PlayerMarker(
                    key: Key('marker-${p.name}'),
                    initials: playerInitials(config, p),
                    color: teamColor(p.side),
                    size: _marker,
                    ring: true,
                  ),
                ),
              if (playing)
                Positioned(
                  left: serverAt.dx + 8,
                  top: serverAt.dy - 30,
                  child: Container(
                    key: const Key('serve-marker'),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6)),
                    child: ShuttleIcon(
                        size: 12, color: teamTextColor(server.side)),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Offset _spot(PlayerId p, Court court, Side leftSide, Size s) {
    final onLeftEnd = p.side == leftSide;
    // Facing the net, a left-end team's right hand points down the screen.
    final bottom = onLeftEnd ? court == Court.right : court == Court.left;
    return Offset((onLeftEnd ? 0.26 : 0.74) * s.width,
        (bottom ? 0.75 : 0.25) * s.height);
  }
}

class _CourtPainter extends CustomPainter {
  _CourtPainter({this.serve});
  final (Offset, Offset)? serve;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    double x(double m) => m / 13.4 * w;
    double y(double m) => m / 6.1 * h;

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Offset.zero & size, line);
    for (final m in [0.46, 6.1 - 0.46]) {
      canvas.drawLine(Offset(0, y(m)), Offset(w, y(m)), line);
    }
    for (final m in [6.7 - 1.98, 6.7 + 1.98, 0.76, 13.4 - 0.76]) {
      canvas.drawLine(Offset(x(m), 0), Offset(x(m), h), line);
    }
    canvas.drawLine(Offset(0, y(3.05)), Offset(x(6.7 - 1.98), y(3.05)), line);
    canvas.drawLine(Offset(x(6.7 + 1.98), y(3.05)), Offset(w, y(3.05)), line);

    // Net with posts, reaching past the sidelines.
    final net = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w / 2, -8), Offset(w / 2, h + 8), net);
    canvas.drawCircle(Offset(w / 2, -8), 3, net);
    canvas.drawCircle(Offset(w / 2, h + 8), 3, net);

    final s = serve;
    if (s != null) {
      final (from, to) = s;
      final mid = Offset.lerp(from, to, 0.5)!;
      final d = to - from;
      // Bow the flight path slightly so it reads as a shot, not a line.
      final bend = Offset(-d.dy, d.dx) * 0.15 * (d.dx > 0 ? -1 : 1);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(mid.dx + bend.dx, mid.dy + bend.dy, to.dx, to.dy);
      final dash = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (final PathMetric m in path.computeMetrics()) {
        // Skip the parts hidden under the two markers.
        for (var t = 18.0; t < m.length - 18; t += 8) {
          canvas.drawPath(m.extractPath(t, (t + 4).clamp(0, m.length - 18)), dash);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CourtPainter old) => old.serve != serve;
}
