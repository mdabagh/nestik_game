import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'brand.dart';

/// App icon / mascot: a single theater mask fusing comedy (smiling right half)
/// and tragedy (frowning left half) — a double-faced "spy vs mafia" mask.
/// Classic ivory/indigo/gold palette for a grown-up party-game brand.
class MaskLogo extends StatelessWidget {
  final double size;
  final bool glow;

  const MaskLogo({super.key, this.size = 120, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MaskPainter(glow: glow),
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter({required this.glow});

  final bool glow;

  // Classic "stage" tones
  static const _ivoryLight = Color(0xFFFDF7EC);
  static const _ivory = Color(0xFFF2E4CE);
  static const _ivoryShade = Color(0xFFDCC9AB);
  static const _comedyWarm = Color(0xFFF4D9CC);
  static const _tragedyCool = Color(0xFFE3D8E0);
  static const _liner = Color(0xFF2C2547); // deep indigo ink
  static const _gold = BrandColors.gold;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s * 0.5, s * 0.52);

    if (glow) {
      final halo = Paint()
        ..shader = ui.Gradient.radial(
          c,
          s * 0.62,
          [
            BrandColors.purple.withValues(alpha: 0.20),
            BrandColors.violet.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          const [0, 0.55, 1],
        );
      canvas.drawCircle(c, s * 0.62, halo);
    }

    final rect = Rect.fromCenter(
      center: c,
      width: s * 0.74,
      height: s * 0.84,
    );
    final mask = _maskPath(rect);

    // Base ivory fill
    final baseFill = Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        [_ivoryLight, _ivory, _ivoryShade],
        const [0, 0.55, 1],
      );
    canvas.drawPath(mask, baseFill);

    // Left half = tragedy (cool wash + frowning features)
    canvas.save();
    canvas.clipPath(mask);
    final leftCool = Paint()
      ..shader = ui.Gradient.linear(
        rect.center,
        rect.centerLeft,
        [Colors.transparent, _tragedyCool.withValues(alpha: 0.9)],
      );
    canvas.drawRect(rect, leftCool);
    canvas.restore();

    // Right half = comedy (warm wash)
    canvas.save();
    canvas.clipPath(mask);
    final rightWarm = Paint()
      ..shader = ui.Gradient.linear(
        rect.center,
        rect.centerRight,
        [Colors.transparent, _comedyWarm.withValues(alpha: 0.9)],
      );
    canvas.drawRect(rect, rightWarm);
    canvas.restore();

    // Gold outline
    final outline = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(mask, outline);

    // --- Features ---
    final line = Paint()
      ..color = _liner
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round;

    // Eyes (almonds)
    _almond(canvas, rect, Offset(rect.center.dx - s * 0.20, rect.top + s * 0.34), s * 0.085, s * 0.030, 0.18);
    _almond(canvas, rect, Offset(rect.center.dx + s * 0.20, rect.top + s * 0.34), s * 0.085, s * 0.030, -0.18);

    // Brows: left droops (tragedy), right lifts (comedy)
    final brow = Paint()
      ..color = _liner
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.016
      ..strokeCap = StrokeCap.round;
    final leftBrow = Path()
      ..moveTo(rect.left + s * 0.10, rect.top + s * 0.20)
      ..quadraticBezierTo(
        rect.center.dx - s * 0.20,
        rect.top + s * 0.10,
        rect.center.dx - s * 0.075,
        rect.top + s * 0.23,
      );
    canvas.drawPath(leftBrow, brow);
    final rightBrow = Path()
      ..moveTo(
        rect.center.dx + s * 0.075,
        rect.top + s * 0.26,
      )
      ..quadraticBezierTo(
        rect.center.dx + s * 0.20,
        rect.top + s * 0.105,
        rect.right - s * 0.08,
        rect.top + s * 0.22,
      );
    canvas.drawPath(rightBrow, brow);

    // Nose (bronze)
    final nose = Path()
      ..moveTo(rect.center.dx, rect.bottom - s * 0.42)
      ..quadraticBezierTo(
        rect.center.dx - s * 0.045,
        rect.bottom - s * 0.31,
        rect.center.dx,
        rect.bottom - s * 0.27,
      )
      ..quadraticBezierTo(
        rect.center.dx + s * 0.045,
        rect.bottom - s * 0.31,
        rect.center.dx,
        rect.bottom - s * 0.42,
      )
      ..close();
    canvas.drawPath(nose, Paint()..color = _gold);

    // Tear under the tragedy (left) eye
    canvas.drawCircle(
      Offset(rect.center.dx - s * 0.22, rect.top + s * 0.44),
      s * 0.027,
      Paint()..color = _gold,
    );

    // Mouths: left frowns, right smiles
    final leftMouth = Path()
      ..moveTo(rect.left + s * 0.10, rect.bottom - s * 0.22)
      ..quadraticBezierTo(
        rect.center.dx - s * 0.16,
        rect.bottom - s * 0.10,
        rect.center.dx - s * 0.03,
        rect.bottom - s * 0.20,
      );
    canvas.drawPath(leftMouth, line);
    final rightMouth = Path()
      ..moveTo(rect.center.dx + s * 0.03, rect.bottom - s * 0.24)
      ..quadraticBezierTo(
        rect.center.dx + s * 0.16,
        rect.bottom - s * 0.14,
        rect.right - s * 0.08,
        rect.bottom - s * 0.20,
      );
    canvas.drawPath(rightMouth, line);
  }

  Path _maskPath(Rect r) {
    final left = r.left;
    final right = r.right;
    final top = r.top;
    final bottom = r.bottom;
    final cx = r.center.dx;

    return Path()
      ..moveTo(cx, top)
      // left temple + cheek
      ..quadraticBezierTo(left + (cx - left) * 0.22, top, left, top + r.height * 0.28)
      // left cheek bulge
      ..quadraticBezierTo(
        left - r.width * 0.06,
        top + r.height * 0.52,
        left + r.width * 0.10,
        top + r.height * 0.70,
      )
      // left jaw → chin
      ..quadraticBezierTo(left + r.width * 0.28, bottom - r.height * 0.08, cx, bottom)
      // right jaw
      ..quadraticBezierTo(
        right - r.width * 0.28,
        bottom - r.height * 0.08,
        right - r.width * 0.10,
        top + r.height * 0.70,
      )
      // right cheek bulge
      ..quadraticBezierTo(
        right + r.width * 0.06,
        top + r.height * 0.52,
        right,
        top + r.height * 0.28,
      )
      // right temple back to top
      ..quadraticBezierTo(right - (right - cx) * 0.22, top, cx, top)
      ..close();
  }

  void _almond(
    Canvas canvas,
    Rect r,
    Offset center,
    double halfW,
    double halfH,
    double angle,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-halfW, 0)
      ..quadraticBezierTo(-halfW * 0.3, halfH * 1.6, 0, 0)
      ..quadraticBezierTo(halfW * 0.3, halfH * 1.6, halfW, 0)
      ..quadraticBezierTo(halfW * 0.3, -halfH * 1.6, 0, 0)
      ..quadraticBezierTo(-halfW * 0.3, -halfH * 1.6, -halfW, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = _liner);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) =>
      oldDelegate.glow != glow;
}