import 'package:flutter/material.dart';

/// A glossy, pseudo-3D game icon: extruded depth, radial gradient orb,
/// glassy highlight sweep and a soft colored halo glow.
class ThreeDIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool glow;

  const ThreeDIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 64,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Color.lerp(color, Colors.black, 0.30)!;
    final topLight = Color.lerp(color, Colors.white, 0.62)!;
    final face = Color.lerp(color, Colors.white, 0.20)!;

    final orb = SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          children: [
            // Depth extrusion (bottom thickness)
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, size * 0.055),
                child: ColoredBox(color: dark),
              ),
            ),
            // Main radial-gradient sphere
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.5),
                    radius: 1.15,
                    colors: [topLight, face, color, dark],
                    stops: const [0.0, 0.35, 0.72, 1.0],
                  ),
                ),
              ),
            ),
            // Glassy highlight sweep (top-left)
            Positioned.fill(
              child: Align(
                alignment: const Alignment(-0.55, -0.68),
                child: Transform.rotate(
                  angle: -0.55,
                  child: Container(
                    width: size * 0.95,
                    height: size * 0.32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.5),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top sparkle dot
            Positioned.fill(
              child: Align(
                alignment: const Alignment(-0.28, -1.0),
                child: Container(
                  width: size * 0.12,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
            ),
            // Glyph
            Positioned.fill(
              child: Center(
                child: Icon(
                  icon,
                  size: size * 0.52,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: dark.withValues(alpha: 0.55),
                      blurRadius: size * 0.05,
                      offset: Offset(0, size * 0.03),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!glow) return orb;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              width: size * 1.5,
              height: size * 1.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.4),
                    color.withValues(alpha: 0),
                  ],
                  stops: const [0, 1],
                ),
              ),
            ),
          ),
          orb,
        ],
      ),
    );
  }
}