import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// App Colors
// ============================================================

class AppColors {
  static const Color bgTop = Color(0xFF17133D);
  static const Color bgBottom = Color(0xFF0D0B24);
  static const Color card = Color(0xFF191631);
  static const Color purple = Color(0xFF6C4DFF);
  static const Color accent = Color(0xFF9C7BFF);
  static const Color border = Color(0xFF765AFF);
  static const Color primaryText = Colors.white;
  static const Color mutedText = Color(0xFFB8B3D0);
  static const Color faintText = Color(0xFF88839F);
  static const Color green = Color(0xFF39BFA7);
  static const Color red = Color(0xFFE84D8A);
  static const Color orange = Color(0xFFE58B32);
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
// Game Shell - صفحه پایه‌ی بازی‌ها
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // Header
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    if (!showBack) const SizedBox(width: 46),
                    if (showBack)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// دکمه‌ی گرادیانی برجسته
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
    this.color = AppColors.purple,
    this.height = 56,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
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
            foregroundColor: Colors.white,
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.32),
              blurRadius: 18,
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
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: inner,
        ),
      ),
    );
  }
}

// ============================================================
// کارت آیتم تاریک
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
        borderRadius:
            radius ?? BorderRadius.circular(20),
        color: AppColors.card,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.06),
        ),
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
    final boxStyle = BoxDecoration(
      color: AppColors.purple.withValues(alpha: 0.16),
      shape: BoxShape.circle,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(
          Icons.remove_rounded,
          value > min
              ? () => onChanged(value - 1)
              : null,
          boxStyle,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF241E4D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _stepBtn(
          Icons.add_rounded,
          value < max ? () => onChanged(value + 1) : null,
          boxStyle,
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap, BoxDecoration box) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: box,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: onTap == null ? AppColors.faintText : Colors.white,
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
        color: AppColors.mutedText,
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
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes.toString().padLeft(2, '0')}:$m:$s';
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
    final value = int.tryParse(cleaned, radix: 16) ?? 0x6C4DFF;
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
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.help_outline_rounded,
          color: Colors.white,
          size: 24,
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
      subtitle: 'نکته‌های مهم بازی',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF29205D), Color(0xFF19143B)],
              ),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.35),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
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
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.accent,
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
                        color: AppColors.mutedText,
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