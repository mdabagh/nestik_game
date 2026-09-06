import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';
import 'game_background.dart';
import 'mask_logo.dart';

class _Floaty {
  const _Floaty(this.alignment, this.emoji, this.phase, this.size);
  final Alignment alignment;
  final String emoji;
  final double phase;
  final double size;
}

const _floaties = [
  _Floaty(Alignment(-0.80, -0.55), '🎲', 0.0, 32),
  _Floaty(Alignment(0.84, -0.40), '🎭', 0.45, 36),
  _Floaty(Alignment(-0.82, 0.55), '🕵️', 1.1, 38),
  _Floaty(Alignment(0.80, 0.62), '🃏', 0.7, 34),
  _Floaty(Alignment(0.0, -0.98), '💜', 0.9, 24),
];

/// Playful startup screen: the mascot pops in (elastic), the brand slides up,
/// floating emojis bob around it, then it fades into the [nextBuilder] screen.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final WidgetBuilder nextBuilder;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 3200),
    required this.nextBuilder,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      widget.duration + const Duration(milliseconds: 300),
      _goNext,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => widget.nextBuilder(context),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;
    final pop = Curves.elasticOut.transform((t / 0.62).clamp(0.0, 1.0));
    final titleFade = Curves.easeOutCubic.transform(((t - 0.30) / 0.28).clamp(0.0, 1.0));
    final titleOffset = 22 * (1 - titleFade);
    final tagFade = ((t - 0.52) / 0.30).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logoStage(t, pop),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: titleFade,
                      child: Transform.translate(
                        offset: Offset(0, titleOffset),
                        child: GradientText(
                          'نستیک گیم',
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: titleFade,
                      child: Transform.translate(
                        offset: Offset(0, titleOffset * 0.6),
                        child: const Text(
                          'NESTIK GAME',
                          style: TextStyle(
                            color: BrandColors.inkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: titleFade,
                      child: Container(
                        width: 54,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: BrandColors.titleGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: tagFade,
                      child: const Text(
                        'مافیا، جاسوس، پانتومیم و…',
                        style: TextStyle(
                          color: BrandColors.inkSoft,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: Column(
                    children: [
                      _loadingDots(),
                      const SizedBox(height: 14),
                      const Text(
                        'نسخه ۱.۰.۰',
                        style: TextStyle(
                          color: BrandColors.inkFaint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoStage(double t, double pop) {
    return SizedBox(
      width: 252,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo behind the mascot
          IgnorePointer(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BrandColors.purple.withValues(alpha: 0.22),
                    BrandColors.pink.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
            ),
          ),
          ..._floaties.map((f) => _floaty(f, t)),
          Transform.scale(
            scale: pop,
            child: const MaskLogo(size: 150, glow: true),
          ),
        ],
      ),
    );
  }

  Widget _floaty(_Floaty f, double t) {
    final l = _loop.value;
    final bob = math.sin(l * 2 * math.pi + f.phase);
    final appear = ((t - 0.18 - f.phase * 0.05) / 0.24).clamp(0.0, 1.0);
    return Positioned.fill(
      child: Align(
        alignment: f.alignment,
        child: Transform.translate(
          offset: Offset(bob * 6, math.cos(l * 2 * math.pi + f.phase) * 7),
          child: Opacity(
            opacity:
                (0.5 + 0.35 * math.sin(l * 2 * math.pi * 1.6 + f.phase)) *
                    appear,
            child: Text(f.emoji, style: TextStyle(fontSize: f.size)),
          ),
        ),
      ),
    );
  }

  Widget _loadingDots() {
    const colors = [
      BrandColors.purple,
      BrandColors.pink,
      BrandColors.cyan,
    ];
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final l = _loop.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final ph = l * 2 * math.pi + i * 2.1;
            final scale = 1 + 0.35 * math.sin(ph);
            final opacity = 0.45 + 0.55 * math.sin(ph);
            return Container(
              width: 8 * scale,
              height: 8 * scale,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: colors[i].withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}