import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'mafia/presentation/mafia_browse_screen.dart';
import 'screens/pantomime_screen.dart';
import 'screens/spy_screen.dart';
import 'screens/word_guess_screen.dart';
import 'shared.dart';
import 'ui/brand.dart';
import 'ui/game_background.dart';
import 'ui/glass_card.dart';
import 'ui/mask_logo.dart';
import 'ui/splash_screen.dart';
import 'ui/three_d_icon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NestikGameApp());
}

// ============================================================
// App
// ============================================================

class NestikGameApp extends StatelessWidget {
  const NestikGameApp({super.key});

  static Widget _buildHome(BuildContext _) => const HomeScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nestik Game',
      theme: AppTheme.themeData,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(nextBuilder: _buildHome),
    );
  }
}

// ============================================================
// Home Screen — Redesigned: glass cards + 3D icons + animated light background
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
        _toast(context, 'باز کردن لینک بازار امکان\u200cپذیر نبود');
      }
    } catch (_) {
      if (context.mounted) {
        _toast(context, 'باز کردن لینک بازار امکان\u200cپذیر نبود');
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
          text: '\uD83C\uDFAE بیا با هم Nestik Game بازی کنیم!\n\n'
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
        _toast(context, 'اشتراک\u200cگذاری انجام نشد');
      }
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
      ),
    );
  }

  void _openGame(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      _GameData(
        title: 'جاسوس',
        subtitle: 'یکی از شما کلمه\u200cای متفاوت داره…',
        icon: Icons.visibility_off_rounded,
        color: BrandColors.purple,
        screen: const SpyScreen(),
      ),
      _GameData(
        title: 'پانتومیم',
        subtitle: 'بدون حرف زدن نشون بده!',
        icon: Icons.theater_comedy_rounded,
        color: BrandColors.pink,
        screen: const PantomimeScreen(),
      ),
      _GameData(
        title: 'مافیا',
        subtitle: 'شهر خوابه، نقش\u200cها رو بشناس!',
        icon: Icons.bedtime_rounded,
        color: BrandColors.coral,
        screen: const MafiaBrowseScreen(),
      ),
      _GameData(
        title: 'حدس کلمه',
        subtitle: 'کلمه روی پیشونیت رو حدس بزن!',
        icon: Icons.psychology_rounded,
        color: BrandColors.mint,
        screen: const WordGuessScreen(),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GameBackground(
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _heroBanner()),
                SliverToBoxAdapter(child: _sectionLabel()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 214,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _gameTile(context, games[index], index),
                      childCount: games.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _requestCard(context)),
                SliverToBoxAdapter(child: _shareButton(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroBanner() {
    return Reveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: BrandColors.rainbowBorder,
          ),
          child: GlassCard(
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            padding: const EdgeInsets.all(22),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: -52,
                  right: -52,
                  child: _glowBlob(BrandColors.purple, 180),
                ),
                Positioned(
                  bottom: -58,
                  left: -46,
                  child: _glowBlob(BrandColors.pink, 170),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const GradientText(
                            'دنیای نستیک',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'جعبه\u200cابزار دورهمی برای شب\u200cهای مافیا و جاسوسی؛ با دوستان، بدون حوصله\u200cسررفتن.',
                            style: TextStyle(
                              color: BrandColors.inkSoft,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GlassChip(
                                label: '🎲 ۴ بازی',
                                color: BrandColors.purple,
                              ),
                              GlassChip(
                                label: 'رایگان',
                                color: BrandColors.mint,
                                icon: Icons.workspace_premium_rounded,
                              ),
                              GlassChip(
                                label: 'آفلاین',
                                color: BrandColors.cyan,
                                icon: Icons.wifi_off_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF5B21B6),
                            Color(0xFF7C3AED),
                            Color(0xFF9333EA),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.purple.withValues(alpha: 0.45),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(child: MaskLogo(size: 64)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel() {
    return const Reveal(
      delay: Duration(milliseconds: 240),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 28, 22, 14),
        child: Row(
          children: [
            _DiamondDot(),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'بازی\u200cها',
                style: TextStyle(
                  color: BrandColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameTile(BuildContext context, _GameData game, int index) {
    return Reveal(
      delay: Duration(milliseconds: 260 + index * 90),
      child: AnimatedTapScale(
        onTap: () => _openGame(context, game.screen),
        child: GlassCard(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: -38,
                right: -38,
                child: _glowBlob(game.color, 110),
              ),
              Column(
                children: [
                  ThreeDIcon(icon: game.icon, color: game.color, size: 60),
                  const Spacer(),
                  Text(
                    game.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrandColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrandColors.inkSoft,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: game.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'شروع',
                          style: TextStyle(
                            color: game.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: game.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestCard(BuildContext context) {
    return Reveal(
      delay: const Duration(milliseconds: 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: AnimatedTapScale(
          onTap: () => _openBazaar(context),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: BrandColors.rainbowBorder,
            ),
            child: GlassCard(
              borderRadius: const BorderRadius.all(Radius.circular(26)),
              tint: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const ThreeDIcon(
                    icon: Icons.storefront_rounded,
                    color: BrandColors.gold,
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'درخواست بازی',
                          style: TextStyle(
                            color: BrandColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'بازی مدنظرت رو از ما بخواه؛ اسمش رو کامنت کن!',
                          style: TextStyle(
                            color: BrandColors.inkSoft,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: BrandColors.inkFaint,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shareButton(BuildContext context) {
    return Reveal(
      delay: const Duration(milliseconds: 660),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: BrandColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: BrandColors.purple.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () => _shareApp(context),
              child: const SizedBox(
                height: 58,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'دعوت از دوستان',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Game Model
// ============================================================

class _GameData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _GameData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _DiamondDot extends StatelessWidget {
  const _DiamondDot();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785,
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          gradient: BrandColors.rainbowBorder,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}