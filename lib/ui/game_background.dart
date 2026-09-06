import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Animated minimal "aurora" background: a slowly rotating color-wheel glow,
/// drifting hue-cycling blobs and gently twinkling geometric sparkles — calm,
/// colorful, never childish.
class GameBackground extends StatelessWidget {
  final Widget? child;

  const GameBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _AnimatedMesh(),
        if (child != null)
          Positioned.fill(
            child: child!,
          ),
      ],
    );
  }
}

class _AnimatedMesh extends StatefulWidget {
  const _AnimatedMesh();

  @override
  State<_AnimatedMesh> createState() => _AnimatedMeshState();
}

class _AnimatedMeshState extends State<_AnimatedMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _AuroraPainter(t: _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Orb {
  const _Orb(
    this.x,
    this.y,
    this.radius,
    this.hueSeed,
    this.fh,
    this.fv,
    this.ampX,
    this.ampY,
    this.phase,
  );

  final double x; // base center fraction of width
  final double y; // base center fraction of height
  final double radius; // fraction of shortest side
  final double hueSeed; // base hue
  final double fh; // horizontal drift frequency
  final double fv; // vertical drift frequency
  final double ampX; // horizontal drift amplitude (fraction of width)
  final double ampY; // vertical drift amplitude (fraction of height)
  final double phase;
}

class _Sparkle {
  const _Sparkle(
    this.x,
    this.y,
    this.radius,
    this.hueSeed,
    this.speed,
    this.phase,
  );

  final double x;
  final double y;
  final double radius;
  final double hueSeed;
  final double speed;
  final double phase;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t});

  final double t;

  static const List<_Orb> _orbs = [
    _Orb(0.16, 0.16, 0.32, 268, 0.07, 0.10, 0.07, 0.05, 0.0),
    _Orb(0.86, 0.18, 0.27, 325, 0.11, 0.08, 0.06, 0.06, 1.6),
    _Orb(0.10, 0.80, 0.30, 205, 0.09, 0.12, 0.07, 0.05, 3.0),
    _Orb(0.86, 0.84, 0.24, 48, 0.12, 0.09, 0.06, 0.06, 4.4),
    _Orb(0.50, 0.46, 0.22, 158, 0.08, 0.15, 0.08, 0.04, 2.2),
  ];

  static final List<_Sparkle> _sparkles = _buildSparkles();

  static List<_Sparkle> _buildSparkles() {
    final rng = math.Random(2026);
    final hues = [268.0, 325.0, 205.0, 48.0, 158.0, 285.0];
    return List.generate(16, (i) {
      return _Sparkle(
        rng.nextDouble(),
        rng.nextDouble(),
        1.2 + rng.nextDouble() * 1.6,
        hues[i % hues.length],
        0.4 + rng.nextDouble() * 1.2,
        rng.nextDouble() * math.pi * 2,
      );
    });
  }

  /// Color wheel traveling slowly around the wheel (vivid, not pastel).
  Color _wheel(double hue) {
    final h = (hue + t * 40) % 360;
    return HSLColor.fromAHSL(1.0, h, 0.72, 0.55).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final short = size.shortestSide;

    // Light base — calm lavender wash
    final base = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, 1.6),
        const [Color(0xFFF8F6FF), Color(0xFFF3EFFB), Color(0xFFEFE9F8)],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, base);

    // Rotating color-wheel glow peeking from the top
    _paintWheel(canvas, w, h);

    // Drifting aurora blobs with breathing hue cycles
    for (final orb in _orbs) {
      _paintOrb(canvas, orb, w, h, short);
    }

    // One elegant light sweep crossing the screen
    _paintStreak(canvas, size, t);
    _paintStreak(canvas, size, (t + 0.5) % 1.0);

    // Twinkling geometric sparkles
    for (final s in _sparkles) {
      _paintSparkle(canvas, s, w, h);
    }
  }

  void _paintWheel(Canvas canvas, double w, double h) {
    final center = Offset(w * 0.5, -h * 0.30);
    final radius = w * 0.95;
    final colors = [268.0, 330.0, 205.0, 58.0, 268.0]
        .map((hue) => _wheel(hue).withValues(alpha: 0.09))
        .toList();

    final sweep = Paint()
      ..shader =
          ui.Gradient.sweep(center, colors, const [0.0, 0.25, 0.5, 0.75, 1.0]);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-t * math.pi * 0.6);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, radius, sweep);
    canvas.restore();
  }

  void _paintOrb(Canvas canvas, _Orb o, double w, double h, double short) {
    final cx = o.x * w + math.sin(t * math.pi * 2 * o.fh + o.phase) * o.ampX * w;
    final cy =
        o.y * h + math.cos(t * math.pi * 2 * o.fv + o.phase) * o.ampY * h;
    final breathe = 1 + 0.12 * math.sin(t * math.pi * 2 * 0.6 + o.phase * 2);
    final radius = o.radius * short * breathe;
    final color = _wheel(o.hueSeed);

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [color.withValues(alpha: 0.30), color.withValues(alpha: 0)],
        const [0.0, 1.0],
      );
    canvas.drawCircle(Offset(cx, cy), radius * 1.2, paint);
  }

  void _paintStreak(Canvas canvas, Size size, double progress) {
    final w = size.width;
    final h = size.height;
    final s = progress;
    final alpha = (math.sin(s * math.pi) * 0.12).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    final start = Offset(-w * 0.20 + s * w * 1.5, -h * 0.35 + s * h * 1.6);
    final end = Offset(start.dx + w * 0.9, start.dy + h * 1.2);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.09
      ..shader = ui.Gradient.linear(
        start,
        end,
        [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: alpha)],
      );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  void _paintSparkle(Canvas canvas, _Sparkle s, double w, double h) {
    final tw = 0.5 + 0.5 * math.sin(t * math.pi * 2 * s.speed + s.phase);
    final alpha = 0.15 + 0.55 * tw;
    final pos = Offset(s.x * w, s.y * h);
    final color = _wheel(s.hueSeed);

    canvas.drawCircle(pos, s.radius, Paint()..color = color.withValues(alpha: alpha));

    // Slowly rotating four-point star
    final star = Paint()
      ..color = color.withValues(alpha: alpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final r = s.radius * 3.4;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(t * math.pi * 0.4 + s.phase);
    final path = Path()
      ..moveTo(-r, 0)
      ..lineTo(r, 0)
      ..moveTo(0, -r)
      ..lineTo(0, r);
    canvas.drawPath(path, star);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => oldDelegate.t != t;
}