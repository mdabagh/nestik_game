import 'package:flutter/material.dart';

/// Vibrant-but-mature palette for adult party games (mafia, spy, ...).
/// Saturated mid-tones — alive and energetic, never pastel-childish and
/// never murky: violet base with rose, emerald, amber, sky accents.
class BrandColors {
  BrandColors._();

  // Accents (vivid, premium — "night-out under stage lights")
  static const Color purple = Color(0xFF6D28D9); // electric violet (primary)
  static const Color violet = Color(0xFF8B5CF6); // bright violet
  static const Color magenta = Color(0xFFC026D3); // vivid fuchsia
  static const Color pink = Color(0xFFE11D48); // rich rose
  static const Color cyan = Color(0xFF0EA5E9); // vivid sky blue
  static const Color mint = Color(0xFF10B981); // vivid emerald
  static const Color gold = Color(0xFFF59E0B); // warm amber
  static const Color coral = Color(0xFFF97316); // vivid orange
  static const Color sky = Color(0xFF38BDF8); // light sky

  // Text
  static const Color ink = Color(0xFF211D3A);
  static const Color inkSoft = Color(0xFF5B5678);
  static const Color inkFaint = Color(0xFF9C97B6);

  static const LinearGradient titleGradient = LinearGradient(
    colors: [purple, magenta, gold],
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