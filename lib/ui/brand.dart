import 'package:flutter/material.dart';

/// Refined light palette — sophisticated "night-out" tones for adult party
/// games (mafia, spy, ...). Deep indigo base with plum, wine, teal accents.
class BrandColors {
  BrandColors._();

  // Accents (muted, premium)
  static const Color purple = Color(0xFF443686); // deep indigo
  static const Color violet = Color(0xFF6A5BD1);
  static const Color magenta = Color(0xFF8A3B66); // plum
  static const Color pink = Color(0xFF9C3F52); // wine
  static const Color cyan = Color(0xFF3E5C8A); // slate blue
  static const Color mint = Color(0xFF2B6E6D); // deep teal
  static const Color gold = Color(0xFFB98A2F); // bronze
  static const Color coral = Color(0xFF37415C); // midnight navy
  static const Color sky = Color(0xFF4E6E9E); // dusty blue

  // Text
  static const Color ink = Color(0xFF24263C);
  static const Color inkSoft = Color(0xFF5B5D79);
  static const Color inkFaint = Color(0xFF999CB8);

  static const LinearGradient titleGradient = LinearGradient(
    colors: [purple, violet, magenta],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [violet, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient rainbowBorder = LinearGradient(
    colors: [gold, magenta, violet, cyan],
  );
}

/// Text painted with an animated gradient shimmer-free static shader mask.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = BrandColors.titleGradient,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// One-shot entrance animation (fade + upwards slide) with a staggerable delay.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double slide;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slide = 18,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + const Duration(milliseconds: 520),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    final start = widget.delay.inMilliseconds;
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(start / total, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.slide * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }
}