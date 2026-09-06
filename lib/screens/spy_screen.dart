import 'dart:async';

import 'package:flutter/material.dart';

import '../shared.dart';

// ============================================================
// مدل کلمه‌ی جاسوس
// ============================================================

class SpyWord {
  final String word;
  final String hint;
  final String emoji;
  final String category;

  const SpyWord({
    required this.word,
    required this.hint,
    required this.emoji,
    required this.category,
  });

  factory SpyWord.fromJson(Map<String, dynamic> json) {
    return SpyWord(
      word: json['word'] as String,
      hint: (json['hint'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '🔍',
      category: (json['category'] as String?) ?? '',
    );
  }
}

// ============================================================
// کارت اختصاص داده‌شده به یک بازیکن
// ============================================================

class SpyCardAssign {
  final bool isSpy;
  final SpyWord word;
  final String category;

  const SpyCardAssign({
    required this.isSpy,
    required this.word,
    required this.category,
  });
}

// ============================================================
// صفحه‌ی اصلی بازی جاسوس
// ============================================================

class SpyScreen extends StatefulWidget {
  const SpyScreen({super.key});

  @override
  State<SpyScreen> createState() => _SpyScreenState();
}

class _SpyScreenState extends State<SpyScreen> {
  int _playerCount = 6;
  int _spyCount = 1;
  Duration _roundTime = const Duration(minutes: 5);
  bool _spyHasHint = false;
  String _difficulty = 'easy';

  List<SpyWord> _easy = [];
  List<SpyWord> _medium = [];
  List<SpyWord> _hard = [];
  bool _dataLoaded = false;

  List<SpyCardAssign>? _deck;
  String? _secretWord;
  int _currentRevealIndex = 0;

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final data = await JsonLoader.load(
      'assets/data/spy_words.json',
    ) as Map<String, dynamic>;
    final difficulties = data['difficulties'] as Map<String, dynamic>;
    setState(() {
      _easy = [
        ...(difficulties['easy'] as List).map(
          (e) => SpyWord.fromJson(e as Map<String, dynamic>),
        ),
      ];
      _medium = [
        ...(difficulties['medium'] as List).map(
          (e) => SpyWord.fromJson(e as Map<String, dynamic>),
        ),
      ];
      _hard = [
        ...(difficulties['hard'] as List).map(
          (e) => SpyWord.fromJson(e as Map<String, dynamic>),
        ),
      ];
      _dataLoaded = true;
    });
  }

  List<SpyWord> _wordsForDifficulty() {
    switch (_difficulty) {
      case 'medium':
        return _medium;
      case 'hard':
        return _hard;
      default:
        return _easy;
    }
  }

  void _startGame() {
    final pool = _wordsForDifficulty();
    final word = pool.isEmpty ? _easy.first : pool[randomInt(pool.length)];

    final total = _playerCount;
    final spies = _spyCount;

    final deck = <SpyCardAssign>[
      for (var i = 0; i < spies; i++)
        SpyCardAssign(isSpy: true, word: word, category: word.category),
      for (var i = spies; i < total; i++)
        SpyCardAssign(isSpy: false, word: word, category: word.category),
    ];

    setState(() {
      _deck = shuffled(deck);
      _secretWord = word.word;
      _currentRevealIndex = 0;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _roundTime.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _resetPlay() {
    _timer?.cancel();
    setState(() {
      _deck = null;
      _currentRevealIndex = 0;
      _remainingSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const GameShell(
        title: 'جاسوس',
        showBack: true,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_deck != null &&
        _remainingSeconds == 0 &&
        _currentRevealIndex >= _deck!.length) {
      return _buildGameOver();
    }

    if (_deck != null && _currentRevealIndex < _deck!.length) {
      return _buildRevealStage();
    }

    if (_deck != null && _currentRevealIndex == _deck!.length) {
      return _buildTimerStage();
    }

    return _buildSetupStage();
  }

  // ============================================================
  // مرحله‌ی تنظیمات
  // ============================================================

  Widget _buildSetupStage() {
    return GameShell(
      title: 'بازی جاسوس',
      subtitle: 'یکی از شما جاسوسه...',
      trailing: HelpTrailing(onPressed: () => _openHelp(context)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _setupSection(
              icon: Icons.groups_rounded,
              title: 'تعداد کل بازیکن\u200cها',
              child: Center(
                child: NumberStepper(
                  value: _playerCount,
                  min: 4,
                  max: 15,
                  onChanged: (v) {
                    setState(() {
                      _playerCount = v;
                      if (_spyCount > v ~/ 2) _spyCount = v ~/ 2;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing14),
            _setupSection(
              icon: Icons.visibility_off_rounded,
              title: 'تعداد جاسوس\u200cها',
              child: Center(
                child: NumberStepper(
                  value: _spyCount,
                  min: 1,
                  max: _playerCount ~/ 2,
                  onChanged: (v) => setState(() => _spyCount = v),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing14),
            _setupSection(
              icon: Icons.timer_outlined,
              title: 'مدت زمان بازی',
              child: Center(
                child: SegmentedButton<Duration>(
                  segments: const [
                    ButtonSegment(
                      value: Duration(minutes: 5),
                      label: Text('۵ دقیقه'),
                    ),
                    ButtonSegment(
                      value: Duration(minutes: 10),
                      label: Text('۱۰ دقیقه'),
                    ),
                    ButtonSegment(
                      value: Duration(minutes: 15),
                      label: Text('۱۵ دقیقه'),
                    ),
                  ],
                  selected: {_roundTime},
                  style: _segmentStyle(),
                  onSelectionChanged: (s) =>
                      setState(() => _roundTime = s.first),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing14),
            DarkCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: SwitchListTile(
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                title: const Text(
                  'آیا جاسوس هم کلمه راهنما داشته باشد؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'اگر روشن باشد، جاسوس فقط دسته\u200cبندی کلمه را می\u200cبیند',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                value: _spyHasHint,
                onChanged: (v) => setState(() => _spyHasHint = v),
              ),
            ),
            const SizedBox(height: AppTheme.spacing14),
            _setupSection(
              icon: Icons.equalizer_rounded,
              title: 'میزان سختی بازی',
              child: Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'easy', label: Text('آسان')),
                    ButtonSegment(value: 'medium', label: Text('متوسط')),
                    ButtonSegment(value: 'hard', label: Text('سخت')),
                  ],
                  selected: {_difficulty},
                  style: _segmentStyle(),
                  onSelectionChanged: (s) =>
                      setState(() => _difficulty = s.first),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            AnimatedTapScale(
              onTap: _startGame,
              child: const GlowButton(
                label: 'شروع بازی',
                icon: Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _segmentStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppTheme.primary.withValues(alpha: 0.12)
            : AppTheme.surfaceVariant;
      }),
      foregroundColor: WidgetStateProperty.all(AppTheme.textPrimary),
      side: WidgetStateProperty.all(
        BorderSide(color: AppTheme.border),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _setupSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return DarkCard(
      padding: const EdgeInsets.all(AppTheme.spacing14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 19),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing14),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // مرحله‌ی نمایش کارت‌ها
  // ============================================================

  Widget _buildRevealStage() {
    final deck = _deck!;
    final current = deck[_currentRevealIndex];
    final total = deck.length;

    final cardText = current.isSpy
        ? (_spyHasHint ? 'دسته: ${current.category}' : 'جاسوس')
        : current.word.word;
    final cardEmoji = current.isSpy ? '🕵️' : current.word.emoji;
    final flipHint = current.isSpy
        ? (_spyHasHint
              ? 'تو جاسوسی! فقط دسته\u200cبندی را می\u200cدانی، نه خود کلمه. 🤫'
              : 'تو جاسوسی! کلمه\u200cی اصلی را نمی\u200cدانی. وظیفه\u200cی تو مخفی ماندن است. 🤫')
        : 'کلمه\u200cی اصلی را می\u200cبینی. سعی کن بدون لو دادن کلمه، زرنگ باشی!';

    return GameShell(
      title: 'کارت نفر ${_currentRevealIndex + 1}',
      subtitle: 'از $total نفر',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                final seen = i < _currentRevealIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 34,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: seen
                        ? AppTheme.primary
                        : AppTheme.border.withValues(alpha: 0.4),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'این کارت را فقط تو ببین! 🔒',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.0).animate(anim),
                        child: child,
                      );
                    },
                    child: _RoleCard(
                      key: ValueKey(_currentRevealIndex),
                      emoji: cardEmoji,
                      title: cardText,
                      subtitle: flipHint,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing28),
                  AnimatedTapScale(
                    onTap: () {
                      setState(() => _currentRevealIndex += 1);
                      if (_currentRevealIndex == total) {
                        _startTimer();
                      }
                    },
                    child: GlowButton(
                      label: _currentRevealIndex == total - 1
                          ? 'همه دیدند · شروع تایمر ⏳'
                          : 'دیدم · نفر بعدی',
                      icon: _currentRevealIndex == total - 1
                          ? Icons.timer_rounded
                          : Icons.arrow_back_rounded,
                      color: _currentRevealIndex == total - 1
                          ? AppTheme.citizenGreen
                          : AppTheme.primary,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  TextButton(
                    onPressed: _resetPlay,
                    child: const Text(
                      'لغو و بازگشت به تنظیمات',
                      style: TextStyle(color: AppTheme.textSecondary),
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

  // ============================================================
  // مرحله‌ی تایمر
  // ============================================================

  Widget _buildTimerStage() {
    final total = _roundTime.inSeconds;
    final progress = _remainingSeconds / total;
    final mm = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return GameShell(
      title: 'بحث و گفتگو! 🗣️',
      subtitle: 'همه کارت\u200cها دیده شد · کلمه را لو ندهید',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'حالا هیجان شروع می\u200cشود! بقیه باید جاسوس را پیدا کنند. 🕵️',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing28),
          Container(
            width: 230,
            height: 230,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
              color: AppTheme.cardBg,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Text(
                      '$mm:$ss',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'زمان مانده',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          const Text(
            'اگر جاسوس رای آورد، او برنده است!\nاگر مردم او را پیدا کردند، شما برنده\u200cاید!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // پایان بازی
  // ============================================================

  void _playAgain() {
    setState(() {
      _deck = null;
      _currentRevealIndex = 0;
      _remainingSeconds = 0;
    });
    _startGame();
  }

  void _backToSetup() {
    setState(() {
      _deck = null;
      _currentRevealIndex = 0;
      _remainingSeconds = 0;
    });
  }

  Widget _buildGameOver() {
    return GameShell(
      title: 'زمان تمام شد! ⏰',
      subtitle: 'نفرات جاسوس را مشخص کنید',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.independentOrange.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.independentOrange.withValues(alpha: 0.4),
                ),
              ),
              child: const Center(
                child: Text('⏰', style: TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            const Text(
              'زمان بحث تمام شد!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'حالا گروه رای بدهد: کدام نفر جاسوس بود؟\nکلمه\u200cی واقعی: $_secretWord',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.7,
              ),
            ),
            const SizedBox(height: AppTheme.spacing28),
            AnimatedTapScale(
              onTap: _playAgain,
              child: GlowButton(
                label: 'بازی مجدد با همین تنظیمات 🔁',
                icon: Icons.replay_rounded,
                color: AppTheme.citizenGreen,
                onPressed: () {},
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            AnimatedTapScale(
              onTap: _backToSetup,
              child: GlowButton(
                label: 'رفتن به تنظیمات بازی',
                icon: Icons.tune_rounded,
                filled: false,
                color: AppTheme.primary,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HelpPage(
          title: 'جاسوس',
          icon: Icons.visibility_off_rounded,
          steps: [
            'همه دور هم می\u200cنشینند و تعداد نفرات و جاسوس\u200cها مشخص می\u200cشود.',
            'یک کلمه به صورت تصادفی انتخاب و به همه نشان داده می\u200cشود؛ فقط جاسوس کلمه را نمی\u200cداند (یا فقط دسته\u200cبندی را می\u200cداند).',
            'گوشی را نفر به نفر بدهید. هر کس کارت خودش را ببیند و بعد نفر بعدی را صدا بزند.',
            'بعد از دیدن همه\u200cی کارت\u200cها، تایمر شروع و گفتگو آغاز می\u200cشود.',
            'بازیکن\u200cها با پرسیدن سوال و استدلال باید جاسوس را پیدا کنند و جاسوس هم باید طوری رفتار کند که لو نرود.',
            'وقتی زمان تمام شد، گروه به جاسوس (یا جاسوس\u200cها) رای می\u200cدهد. اگر پیدا شود، مردم برنده\u200cاند و اگر نه، جاسوس برنده است!',
          ],
        ),
      ),
    );
  }
}

// ============================================================
// کارت نقش (ظاهر یکسان برای همه)
// ============================================================

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _RoleCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
