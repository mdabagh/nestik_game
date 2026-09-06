import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'mafia/presentation/mafia_browse_screen.dart';
import 'screens/pantomime_screen.dart';
import 'screens/spy_screen.dart';
import 'screens/word_guess_screen.dart';
import 'shared.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NestikGameApp());
}

// ============================================================
// App
// ============================================================

class NestikGameApp extends StatelessWidget {
  const NestikGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nestik Game',
      theme: AppTheme.themeData,
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// Home Screen
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String bazaarUrl = 'https://cafebazaar.ir/app/YOUR_PACKAGE_NAME';

  Future<void> _openBazaar(BuildContext context) async {
    final uri = Uri.parse(bazaarUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'باز کردن لینک بازار امکان\u200cپذیر نبود',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'باز کردن لینک بازار امکان\u200cپذیر نبود',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Nestik Game',
          subject: 'دعوت به بازی Nestik Game',
          text:
              '\uD83C\uDFAE بیا با هم Nestik Game بازی کنیم!\n\n'
              'بازی\u200cهای دورهمی و سرگرم\u200cکننده برای جمع دوستانه.\n\n'
              'دانلود برنامه از بازار:\n'
              '$bazaarUrl',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'اشتراک\u200cگذاری انجام نشد',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  void _openGame(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      GameItem(
        title: 'جاسوس',
        description: 'یکی از شما جاسوسه...',
        icon: Icons.visibility_off_rounded,
        color: const Color(0xFF6C5CE7),
      ),
      GameItem(
        title: 'پانتومیم',
        description: 'بگو، اما با حرف زدن نه!',
        icon: Icons.theater_comedy_rounded,
        color: const Color(0xFFE03131),
      ),
      GameItem(
        title: 'مافیا',
        description: 'شهر در خواب است...',
        icon: Icons.person_rounded,
        color: const Color(0xFFE8590C),
      ),
      GameItem(
        title: 'حدس کلمه',
        description: 'کلمه رو حدس بزن!',
        icon: Icons.question_mark_rounded,
        color: const Color(0xFF2B8A3E),
      ),
      GameItem(
        title: 'درخواست بازی',
        description: 'برای درخواست بازی، نامش را در بازار کامنت کنید',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF868E96),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Header
                Text(
                  'Nestik Game',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'بازی\u200cهای دورهمی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                // Game Cards
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: games.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final isLast = index == games.length - 1;
                      return AnimatedTapScale(
                        onTap: isLast
                            ? () => _openBazaar(context)
                            : () => _openGame(context, _screenFor(index)),
                        child: GameCard(
                          game: games[index],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Share Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      color: AppTheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _shareApp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        ),
                      ),
                      icon: const Icon(
                        Icons.group_add_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'دعوت از دوستان',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _screenFor(int index) {
    switch (index) {
      case 0:
        return const SpyScreen();
      case 1:
        return const PantomimeScreen();
      case 2:
        return const MafiaBrowseScreen();
      case 3:
        return const WordGuessScreen();
      default:
        return const SpyScreen();
    }
  }
}

// ============================================================
// Game Model
// ============================================================

class GameItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const GameItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ============================================================
// Game Card (Light Theme — Horizontal Minimal)
// ============================================================

class GameCard extends StatelessWidget {
  final GameItem game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: game.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Icon(game.icon, color: game.color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  game.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_left_rounded,
            color: AppTheme.textHint,
            size: 26,
          ),
        ],
      ),
    );
  }
}
