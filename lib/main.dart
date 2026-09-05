import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const NestikGameApp());
}

// ============================================================
// App Constants
// ============================================================

/// لینک واقعی برنامه در بازار را اینجا قرار بده.
///
/// مثال:
/// https://cafebazaar.ir/app/your.package.name
const String BAZAAR_URL = 'https://cafebazaar.ir/app/YOUR_PACKAGE_NAME';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0B24),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// Flutter Widget Preview
// ============================================================

@Preview(
  name: 'Nestik Game Home',
  size: Size(390, 844),
)
Widget nestikGamePreview() {
  return const NestikGameApp();
}

// ============================================================
// Home Screen
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ==========================================================
  // Open Bazaar
  // ==========================================================

  Future<void> _openBazaar(BuildContext context) async {
    final uri = Uri.parse(BAZAAR_URL);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'باز کردن لینک بازار امکان‌پذیر نبود',
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
              'باز کردن لینک بازار امکان‌پذیر نبود',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  // ==========================================================
  // Share App
  // ==========================================================

  Future<void> _shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Nestik Game',
          subject: 'دعوت به بازی Nestik Game',
          text:
              '🎮 بیا با هم Nestik Game بازی کنیم!\n\n'
              'بازی‌های دورهمی و سرگرم‌کننده برای جمع دوستانه.\n\n'
              'دانلود برنامه از بازار:\n'
              '$BAZAAR_URL',
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
              'اشتراک‌گذاری انجام نشد',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      GameItem(
        title: 'جاسوس',
        description: 'یکی از شما جاسوسه...',
        icon: Icons.visibility_off_rounded,
        color: const Color(0xFF6C4DFF),
      ),
      GameItem(
        title: 'پانتومیم',
        description: 'بگو، اما با حرف زدن نه!',
        icon: Icons.theater_comedy_rounded,
        color: const Color(0xFFE84D8A),
      ),
      GameItem(
        title: 'مافیا',
        description: 'شهر در خواب است...',
        icon: Icons.person_rounded,
        color: const Color(0xFFE58B32),
      ),
      GameItem(
        title: 'حدس کلمه',
        description: 'کلمه رو حدس بزن!',
        icon: Icons.question_mark_rounded,
        color: const Color(0xFF39BFA7),
      ),
      GameItem(
        title: 'و بیشتر',
        description: 'بازی‌های هیجان‌انگیز دیگر',
        icon: Icons.more_horiz_rounded,
        color: const Color(0xFF625D88),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF17133D),
                  Color(0xFF0D0B24),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  // ========================================================
                  // Header
                  // ========================================================

                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      // Logo / Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFF9C7BFF),
                                  ],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'Nestik Game',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'بازی‌های دورهمی',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Color(0xFFB8B3D0),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Notification
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C4DFF)
                              .withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ========================================================
                  // Welcome / Bazaar Card
                  // ========================================================

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _openBazaar(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF29205D),
                              Color(0xFF19143B),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF765AFF)
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ==================================================
                            // Icon - Right
                            // ==================================================

                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C4DFF),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C4DFF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_esports_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // ==================================================
                            // Text - Close to Icon
                            // ==================================================

                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'وقت بازیه! 🎮',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'یک بازی انتخاب کن و دورهمی رو شروع کن',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Color(0xFFAAA5C2),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Bazaar suggestion
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'بازی بعدی رو در کامنت‌های بازار پیشنهاد بدید',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            color: const Color(0xFFBFAEFF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Color(0xFFBFAEFF),
                                        size: 11,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ========================================================
                  // Games Title
                  // ========================================================

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'بازی‌ها',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ========================================================
                  // Games List
                  // ========================================================

                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: games.length,
                      separatorBuilder: (_, _) {
                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (context, index) {
                        return GameCard(
                          game: games[index],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ========================================================
                  // Invite Button
                  // ========================================================

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7655FF),
                            Color(0xFF5535D8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C4DFF)
                                .withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _shareApp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19),
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
// Game Card
// ============================================================

class GameCard extends StatelessWidget {
  final GameItem game;

  const GameCard({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          // TODO: Open game
        },
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF191631),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // ==========================================================
              // Game Icon - Right
              // ==========================================================

              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: game.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  game.icon,
                  color: game.color,
                  size: 31,
                ),
              ),

              // فاصله کمتر بین آیکن و عنوان
              const SizedBox(width: 10),

              // ==========================================================
              // Game Text - Close to Icon
              // ==========================================================

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      game.title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      game.description,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF88839F),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================================
              // Arrow - Left
              // ==========================================================

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF8D87A9),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}