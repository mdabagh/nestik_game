import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;

import '../../shared.dart';
import '../data/mafia_repository.dart';
import '../mafia_models.dart';
import '../mafia_usecases.dart';
import 'mafia_secure.dart';

// ============================================================
// صفحه‌ی توزیع کارت‌های محرمانه مافیا
// ویژگی‌ها: FLAG_SECURE (بدون اسکرین‌شات / Recent Apps)،
// کارت‌های پشت‌ورو یکسان، فقط کارت انتخابی باز می‌شود،
// شمارنده‌ی باقی‌مانده، دیالوگ تأیید خروج، انیمیشن Flip.
// ============================================================

class MafiaDistributionScreen extends StatefulWidget {
  final MafiaRepository repository;
  final DistributionSession session;

  const MafiaDistributionScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  @override
  State<MafiaDistributionScreen> createState() =>
      _MafiaDistributionScreenState();
}

class _MafiaDistributionScreenState extends State<MafiaDistributionScreen> {
  late List<DistributionCard> _cards;
  final Map<String, MafiaRole> _roles = {};

  @override
  void initState() {
    super.initState();
    _cards = List.of(widget.session.cards);
    _loadRoles();
    _enableSecure(true);
  }

  @override
  void dispose() {
    _enableSecure(false);
    SystemChrome.setPreferredOrientations(DeviceOrientationValues.all);
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await widget.repository.getRoles();
      if (!mounted) return;
      setState(() {
        for (final r in roles) {
          _roles[r.id] = r;
        }
      });
    } catch (_) {
      //
    }
  }

  Future<void> _enableSecure(bool on) async {
    try {
      await SecureWindow.setSecure(on);
    } catch (_) {
      // نادیده
    }
  }

  int get _remaining =>
      _cards.where((c) => c.state != CardState.completed).length;

  /// بازکردن کارت: Card Flip + نمایش لایه‌ی جزئیات نقش.
  /// پس از «مشاهده کردم» کارت COMPLETED می‌شود و به پشت برمی‌گردد.
  Future<void> _reveal(DistributionCard card) async {
    if (card.state == CardState.completed) return;
    final wasAvailable = card.state == CardState.available;
    if (wasAvailable) {
      setState(() {
        _cards = RevealCard.call(_cards, card.id);
      });
    }
    final role = _roleFor(card.roleId);
    if (role == null) {
      if (wasAvailable) {
        setState(() {
          _cards = _revert(card.id);
        });
      }
      return;
    }
    final viewed = await _showRevealSheet(card, role);
    if (!mounted) return;
    if (viewed == true) {
      setState(() {
        _cards = CompleteCard.call(_cards, card.id);
      });
      _maybeComplete();
    } else if (wasAvailable) {
      // بدون تأیید «مشاهده کردم» کارت دوباره پشت‌ورو می‌شود (بدون لو رفتن نقش)
      setState(() {
        _cards = _revert(card.id);
      });
    }
  }

  /// برگرداندن یک کارت REVEALED به AVAILABLE
  List<DistributionCard> _revert(String id) {
    return _cards.map((c) {
      if (c.id != id) return c;
      return c.copyWith(state: CardState.available);
    }).toList();
  }

  /// لایه‌ی نمایش نقش: [نقش] نام + توضیح کوتاه + توضیح کامل + وظیفه + دکمه
  Future<bool?> _showRevealSheet(DistributionCard card, MafiaRole role) {
    final accent = factionColor(role.faction);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        ),
                        child: Text(
                          role.emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.nameFa,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              role.aliases.join(' · '),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    role.shortDescription,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    role.dutyDescription,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'کارت #${card.displayNumber} · فقط خودت ببین 👀',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlowButton(
                    label: 'مشاهده کردم',
                    icon: Icons.visibility_rounded,
                    color: AppTheme.success,
                    height: 50,
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'برگشت به کارت‌ها (هنوز دیده نشده)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _maybeComplete() {
    if (_remaining > 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              '🎉 تقسیم کارت‌ها تمام شد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'همه‌ی ${_cards.length} کارت توزیع شد.\n'
              'حالا نوبت بازی است!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.8,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'بازگشت',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  MafiaRole? _roleFor(String id) => _roles[id];

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onBackPressed();
        if (ok && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              _header(remaining),
              Expanded(
                child: GridView.builder(
                  controller: _gridController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.60,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _cardView(_cards[index], index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final ScrollController _gridController = ScrollController();

  Widget _header(int remaining) {
    final total = _cards.length;
    final completed = total - remaining;
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _onBackPressed,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                  tooltip: 'خروج از توزیع',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.session.scenarioEmoji} '
                  '${widget.session.scenarioTitle}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
                child: Text(
                  'باقی‌مانده: $remaining',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardView(DistributionCard card, int index) {
    switch (card.state) {
      case CardState.available:
        return _cardBack(card, index);
      case CardState.revealed:
        return _cardFront(card);
      case CardState.completed:
        return _cardCompleted(card);
    }
  }

  /// انیمیشن Flip سه‌بعدی بین پشت و روی کارت
  Widget _cardBack(DistributionCard card, int index) {
    return GestureDetector(
      onTap: () => _reveal(card),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final rot = 1.0 - animation.value;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rot * 3.14159),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(-rot * 3.14159),
                  child: child,
                ),
              );
            },
          );
        },
        child: ClipRRect(
          borderRadius: UniformCardDesign.backRadius,
          clipBehavior: Clip.antiAlias,
          child: Container(
            key: ValueKey(card.id),
            decoration: UniformCardDesign.backDecoration(),
            child: Stack(
              children: [
                const _CardCornerGlow(),
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.spa_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 30,
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54),
                      ),
                      child: Text(
                        card.displayNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _cardFront(DistributionCard card) {
    final role = _roleFor(card.roleId);
    return GestureDetector(
      onTap: () => _reveal(card),
      child: ClipRRect(
        borderRadius: UniformCardDesign.frontRadius,
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: UniformCardDesign.frontDecoration(),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceVariant,
                  ),
                  child: Text(
                    card.displayNumber,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    role?.emoji ?? '❓',
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              Text(
                role?.nameFa ?? 'ناشناخته',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.visibility_rounded,
                color: AppTheme.primary.withValues(alpha: 0.7),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// کارت Completed: نقش مخفی شده، کارت به پشت برگشته و غیرفعال است.
  Widget _cardCompleted(DistributionCard card) {
    return ClipRRect(
      borderRadius: UniformCardDesign.backRadius,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: UniformCardDesign.backDecoration(),
            child: Icon(
              Icons.spa_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 26,
            ),
          ),
          const _CardCornerGlow(alpha: 0.16),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                color: Color(0x3337B24C),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    card.displayNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'خروج از تقسیم کارت؟',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'اگر خارج شوید، روند تقسیم کارت‌ها متوقف می‌شود و کارت‌ها دوباره شافل می‌شوند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.8,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'انصراف',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'خروج',
                  style: TextStyle(
                    color: AppTheme.mafiaRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed == true) {
      await _enableSecure(false);
      return true;
    }
    return false;
  }
}

/// جهت‌های پشتیبانی‌شده برای جلوگیری از افقی نگه‌داشتن گوشی
class DeviceOrientationValues {
  static const all = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
}

/// افکت نوری گوشه بالا-راست کارت مافیا؛ با Positioned(top: 0, right: 0)
/// دقیقاً به گوشه می‌چسبد و توسط ClipRRect پدر درون لبه‌های گرد کارت ماسک می‌شود.
class _CardCornerGlow extends StatelessWidget {
  final double alpha;

  const _CardCornerGlow({this.alpha = 0.30});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: IgnorePointer(
        child: SizedBox(
          width: 110,
          height: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.0,
                colors: [
                  Colors.white.withValues(alpha: alpha),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}