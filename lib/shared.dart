import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/game_background.dart';

// ============================================================
// Design System — Light Theme
// ============================================================

class AppTheme {
  static const _fontFamily = 'Vazirmatn';

  static const Color scaffoldBg = Color(0xFFF4F3FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE9ECEF);
  static const Color cardShadow = Color(0xFF000000);

  static const Color primary = Color(0xFF5546C0);
  static const Color primaryLight = Color(0xFF8E80E6);
  static const Color primaryDark = Color(0xFF3E319A);

  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Colors.white;

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  static const Color border = Color(0xFFDEE2E6);
  static const Color divider = Color(0xFFE9ECEF);

  static const Color mafiaRed = Color(0xFFB32742);
  static const Color citizenGreen = Color(0xFF2E7D48);
  static const Color independentOrange = Color(0xFFBB5A21);

  static const Color success = Color(0xFF2E7D48);
  static const Color error = Color(0xFFB32742);
  static const Color warning = Color(0xFFC07717);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: _fontFamily,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: textOnPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  // --- Spacing (8pt grid) ---
  static const double spacing0 = 0;
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing14 = 14;
  static const double spacing16 = 16;
  static const double spacing18 = 18;
  static const double spacing20 = 20;
  static const double spacing22 = 22;
  static const double spacing24 = 24;
  static const double spacing26 = 26;
  static const double spacing28 = 28;
  static const double spacing32 = 32;

  // --- Border Radius ---
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;

  // --- Typography ---
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textHint,
    height: 1.4,
  );

  // --- Decorations ---
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radiusXL),
    border: Border.all(color: cardBorder),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 24,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.85),
    borderRadius: BorderRadius.circular(radiusXXL),
    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 20,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration chipDecoration(bool selected) => BoxDecoration(
    color: selected ? primary.withValues(alpha: 0.12) : cardBg,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: selected ? primary : border,
    ),
  );

  static BoxDecoration outlinedChipDecoration() => BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: border),
  );
}

// ============================================================
// App Colors (kept for backward compatibility)
// ============================================================

class AppColors {
  static const Color bgTop = AppTheme.scaffoldBg;
  static const Color bgBottom = AppTheme.scaffoldBg;
  static const Color card = AppTheme.cardBg;
  static const Color purple = AppTheme.primary;
  static const Color accent = AppTheme.primaryLight;
  static const Color border = AppTheme.border;
  static const Color primaryText = AppTheme.textPrimary;
  static const Color mutedText = AppTheme.textSecondary;
  static const Color faintText = AppTheme.textHint;
  static const Color green = AppTheme.citizenGreen;
  static const Color red = AppTheme.mafiaRed;
  static const Color orange = AppTheme.independentOrange;
}

// ============================================================
// JSON Loader
// ============================================================

class JsonLoader {
  static Future<dynamic> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw);
  }
}

// ============================================================
// Game Shell — صفحه پایه‌ی بازی‌ها (Light Theme)
// ============================================================

class GameShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final Widget? trailing;

  const GameShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: GameBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Frosted Glass AppBar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!showBack) const SizedBox(width: 44),
                      if (showBack)
                        _buildBackButton(context),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ?trailing,
                      if (trailing == null) const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: AppTheme.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

// ============================================================
// دکمه‌ی اصلی (Light Theme)
// ============================================================

class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final bool filled;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppTheme.primary,
    this.height = 56,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    final inner = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (!filled) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(
              color: onPressed == null ? AppTheme.border : color.withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: inner,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          color: onPressed == null ? AppTheme.textHint : color,
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
          child: inner,
        ),
      ),
    );
  }
}

// ============================================================
// کارت روشن
// ============================================================

class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? radius;
  final Color? borderColor;
  final EdgeInsets? margin;

  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
    this.borderColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: radius ?? BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: borderColor ?? AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================
// استپر (افزایش/کاهش عدد)
// ============================================================

class NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const NumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(
          Icons.remove_rounded,
          value > min ? () => onChanged(value - 1) : null,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _stepBtn(
          Icons.add_rounded,
          value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primary.withValues(alpha: 0.12)
              : AppTheme.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppTheme.primary : AppTheme.textHint,
          size: 22,
        ),
      ),
    );
  }
}

// ============================================================
// لیبل بخش
// ============================================================

class LabelText extends StatelessWidget {
  final String text;
  final bool withIcon;

  const LabelText(this.text, {super.key, this.withIcon = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ============================================================
// ابزارهای کمکی
// ============================================================

String formatDuration(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String formatSeconds(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

final Random _rng = Random();

int randomInt(int max) => _rng.nextInt(max);

List<T> shuffled<T>(List<T> input) {
  final list = List<T>.of(input);
  list.shuffle(_rng);
  return list;
}

class AppTint {
  static Color rgbaHex(String hex, {double alpha = 1.0}) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x6C5CE7;
    return Color(value).withValues(alpha: alpha);
  }
}

// ============================================================
// دکمه‌ی رفتن به راهنما
// ============================================================

class HelpTrailing extends StatelessWidget {
  final VoidCallback onPressed;
  const HelpTrailing({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 4),
            const Text(
              'راهنما',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// صفحهی راهنمای ساده
// ============================================================

class HelpPage extends StatelessWidget {
  final String title;
  final List<String> steps;
  final IconData icon;

  const HelpPage({
    super.key,
    required this.title,
    required this.steps,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'راهنمای $title',
      subtitle: 'نکته\u200cهای مهم بازی',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            return DarkCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// Animate Scale Wrapper
// ============================================================

class AnimatedTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const AnimatedTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  @override
  State<AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<AnimatedTapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) {
        _controller.reverse();
        widget.onTap?.call();
      } : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: ScaleTransition(scale: _animation, child: widget.child),
    );
  }
}

// ============================================================
// Universal Game Layout — چیدمان یکپارچه‌ی بازی‌های داخلی
// شامل هدر شیشه‌ای، دکمه برگشت و CTA یکدست
// ============================================================

class UniversalGameLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottomBar;

  const UniversalGameLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = true,
    this.trailing,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: title,
      subtitle: subtitle,
      showBack: showBack,
      trailing: trailing,
      child: child,
    );
  }
}

// ============================================================
// Role Grid Card — نقش در قالب کارت‌های ۳ ستونه
// شامل آیکون ۳D، عنوان و نشانگر (Badge) تیم
// ============================================================

class RoleGridCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback? onTap;
  final bool countBadge;
  final String? countLabel;

  const RoleGridCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    this.onTap,
    this.countBadge = false,
    this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // آیکون/اموجی نقش
            Expanded(
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // عنوان نقش
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // Badge تیم / نقش
            if (badgeLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  countBadge ? '$badgeLabel · $countLabel' : badgeLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
