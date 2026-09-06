import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'brand.dart';

/// Cute kawaii bear mascot logo — vector drawn so it scales at any size.
class BearLogo extends StatelessWidget {
  final double size;
  final bool showPartyHat;

  const BearLogo({super.key, this.size = 120, this.showPartyHat = true});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BearPainter(showPartyHat: showPartyHat),
    );
  }
}

class _BearPainter extends CustomPainter {
  _BearPainter({required this.showPartyHat});

  final bool showPartyHat;

  static const _furLight = Color(0xFFFFF6EA);
  static const _fur = Color(0xFFF8B87E);
  static const _furShade = Color(0xFFE79A5E);
  static const _furDark = Color(0xFF5A3A28);
  static const _snout = Color(0xFFFFF1E0);
  static const _blush = Color(0xFFFFA5B8);
  static const _innerEar = Color(0xFFE8B088);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s * 0.5, s * 0.56);
    final r = s * 0.40;

    final furPaint = Paint()
      ..shader = ui.Gradient.radial(
        c.translate(0, -s * 0.18),
        r * 1.4,
        [_furLight, _fur, _furShade],
        const [0.0, 0.55, 1.0],
      );

    // Ears
    _ear(canvas, s, Offset(c.dx - r * 0.72, c.dy - r * 0.62), r * 0.30);
    _ear(canvas, s, Offset(c.dx + r * 0.72, c.dy - r * 0.62), r * 0.30);

    // Head
    canvas.drawCircle(c, r, furPaint);

    // Snout
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.30),
        width: r * 1.05,
        height: r * 0.78,
      ),
      Paint()..color = _snout,
    );

    // Blush
    final blush = Paint()..color = _blush.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(c.dx - r * 0.66, c.dy + r * 0.18), r * 0.22, blush);
    canvas.drawCircle(Offset(c.dx + r * 0.66, c.dy + r * 0.18), r * 0.22, blush);

    // Eyes
    _eye(canvas, Offset(c.dx - r * 0.38, c.dy - r * 0.02), r * 0.17);
    _eye(canvas, Offset(c.dx + r * 0.38, c.dy - r * 0.02), r * 0.17);

    // Nose
    final noseRect = Rect.fromCenter(
      center: Offset(c.dx, c.dy + r * 0.16),
      width: r * 0.30,
      height: r * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(noseRect, Radius.circular(r * 0.10)),
      Paint()..color = _furDark,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx - r * 0.05, c.dy + r * 0.125),
        width: r * 0.10,
        height: r * 0.05,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Smile
    final mouth = Paint()
      ..color = _furDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.020
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(c.dx - r * 0.16, c.dy + r * 0.30)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.42, c.dx + r * 0.16, c.dy + r * 0.30);
    canvas.drawPath(path, mouth);

    if (showPartyHat) {
      _partyHat(canvas, s, c, r);
    }
  }

  void _ear(Canvas canvas, double s, Offset center, double er) {
    final outer = Paint()
      ..shader = ui.Gradient.radial(
        center,
        er,
        [_fur, _furShade],
        const [0, 1],
      );
    canvas.drawCircle(center, er, outer);
    canvas.drawCircle(
      center.translate(0, er * 0.10),
      er * 0.55,
      Paint()..color = _innerEar,
    );
  }

  void _eye(Canvas canvas, Offset center, double er) {
    canvas.drawCircle(center, er, Paint()..color = _furDark);
    final glint = Paint()..color = Colors.white;
    canvas.drawCircle(center + Offset(-er * 0.30, -er * 0.35), er * 0.28, glint);
    canvas.drawCircle(center + Offset(er * 0.28, -er * 0.28), er * 0.16, glint);
  }

  void _partyHat(Canvas canvas, double s, Offset c, double r) {
    final top = Offset(c.dx, c.dy - r * 1.38);
    final topLeft = Offset(c.dx - r * 0.55, c.dy - r * 0.92);
    final topRight = Offset(c.dx + r * 0.55, c.dy - r * 0.92);

    final hat = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(c.dx - r * 0.05, c.dy - r * 1.12, topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..quadraticBezierTo(c.dx + r * 0.05, c.dy - r * 1.12, top.dx, top.dy)
      ..close();

    final hatPaint = Paint()
      ..shader = ui.Gradient.linear(
        topLeft,
        c + Offset(0, r),
        [BrandColors.purple, BrandColors.pink],
      );
    canvas.drawPath(hat, hatPaint);

    // Stripe accents
    canvas.save();
    canvas.clipPath(hat);
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.45);
    const bandFracs = [0.42, 0.66];
    for (final f in bandFracs) {
      final y = top.dy + (topLeft.dy - top.dy) * f;
      canvas.drawRect(
        Rect.fromLTRB(topLeft.dx, y, topRight.dx, y + s * 0.012),
        stripe,
      );
    }
    canvas.restore();

    // Brim band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          topLeft.dx,
          topLeft.dy - s * 0.014,
          topRight.dx,
          topRight.dy + s * 0.010,
        ),
        Radius.circular(s * 0.012),
      ),
      Paint()..color = BrandColors.gold,
    );

    // Pompom
    canvas.drawCircle(top, s * 0.050, Paint()..color = BrandColors.mint);
    canvas.drawCircle(
      top + Offset(-s * 0.014, -s * 0.014),
      s * 0.016,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _BearPainter oldDelegate) =>
      oldDelegate.showPartyHat != showPartyHat;
}