import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Animated light "gaming" background: soft drifting color orbs, passing light
/// streaks and gently twinkling sparkles over a pastel fantasy gradient.
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
    duration: const Duration(seconds: 18),
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
        painter: _MeshPainter(t: _controller.value),
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
    this.color,
    this.speed,
    this.phase,
    this.amp,
    this.pulse,
  );

  final double x; // fraction of width
  final double y; // fraction of height
  final double radius; // fraction of shortest side
  final Color color;
  final double speed;
  final double phase;
  final double amp; // fraction of width drift
  final double pulse; // radius pulsation strength
}

class _Sparkle {
  const _Sparkle(
    this.x,
    this.y,
    this.radius,
    this.color,
    this.speed,
    this.phase,
    this.large,
  );

  final double x;
  final double y;
  final double radius;
  final Color color;
  final double speed;
  final double phase;
  final bool large;
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.t});

  final double t;

  static const List<_Orb> _orbs = [
    _Orb(0.14, 0.18, 0.34, Color(0x33443686), 0.55, 0.0, 0.05, 0.10),
    _Orb(0.88, 0.14, 0.28, Color(0x309C3F52), 0.72, 1.4, 0.04, 0.12),
    _Orb(0.10, 0.82, 0.30, Color(0x2E2B6E6D), 0.42, 2.8, 0.05, 0.08),
    _Orb(0.82, 0.86, 0.26, Color(0x2EB98A2F), 0.60, 4.2, 0.04, 0.14),
    _Orb(0.55, 0.28, 0.22, Color(0x2E3E5C8A), 0.50, 5.6, 0.06, 0.12),
    _Orb(0.66, 0.62, 0.20, Color(0x2E6A5BD1), 0.80, 0.8, 0.05, 0.10),
    _Orb(0.30, 0.52, 0.16, Color(0x3037415C), 0.92, 3.4, 0.06, 0.14),
  ];

  static final List<_Sparkle> _sparkles = _buildSparkles();

  static List<_Sparkle> _buildSparkles() {
    final rng = math.Random(2026);
    const colors = [
      Color(0xFF8A3B66),
      Color(0xFF3E5C8A),
      Color(0xFF443686),
      Color(0xFFB98A2F),
      Color(0xFF2B6E6D),
    ];
    return List.generate(30, (i) {
      final large = rng.nextBool();
      return _Sparkle(
        rng.nextDouble(),
        rng.nextDouble(),
        large ? 2.6 : 1.5,
        colors[i % colors.length],
        0.5 + rng.nextDouble() * 1.4,
        rng.nextDouble() * math.pi * 2,
        large,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final short = size.shortestSide;

    // Muted, elegant base gradient
    final base = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, 1.6),
        const [Color(0xFFF6F5FC), Color(0xFFF1EFF8), Color(0xFFECE9F4)],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, base);

    // Soft drifting color orbs
    for (final orb in _orbs) {
      _paintOrb(canvas, orb, w, h, short);
    }

    // Passing light streaks
    _paintStreak(canvas, size, t);
    _paintStreak(canvas, size, math.min(1.0, t + 0.55) % 1.0);

    // Twinkling sparkles
    for (final s in _sparkles) {
      _paintSparkle(canvas, s, w, h);
    }
  }

  void _paintOrb(Canvas canvas, _Orb o, double w, double h, double short) {
    final angle = t * math.pi * 2 * o.speed + o.phase;
    final cx = o.x * w + math.cos(angle) * o.amp * w;
    final cy = o.y * h + math.sin(angle) * o.amp * w;
    final radius =
        o.radius * short * (1 + o.pulse * math.sin(angle * 1.7 + o.phase));

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [o.color, o.color.withValues(alpha: 0)],
        const [0.0, 1.0],
      );
    canvas.drawCircle(Offset(cx, cy), radius * 1.2, paint);
  }

  void _paintStreak(Canvas canvas, Size size, double progress) {
    final w = size.width;
    final h = size.height;
    final s = progress;
    // Peak opacity mid-travel
    final alpha = (math.sin(s * math.pi) * 0.28).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    final start = Offset(-w * 0.25 + s * w * 1.4, -h * 0.30 + s * h * 1.7);
    final end = Offset(start.dx + w * 1.1, start.dy + h * 1.35);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.05
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
    final alpha = 0.18 + 0.62 * tw;
    final pos = Offset(s.x * w, s.y * h);

    final dot = Paint()..color = s.color.withValues(alpha: alpha);
    canvas.drawCircle(pos, s.radius, dot);

    if (s.large) {
      final star = Paint()
        ..color = s.color.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      final r = s.radius * 3.2;
      final path = Path()
        ..moveTo(pos.dx - r, pos.dy)
        ..lineTo(pos.dx + r, pos.dy)
        ..moveTo(pos.dx, pos.dy - r)
        ..lineTo(pos.dx, pos.dy + r);
      canvas.drawPath(path, star);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => oldDelegate.t != t;
}