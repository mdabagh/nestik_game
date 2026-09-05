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
    final data = await JsonLoader.load('assets/data/spy_words.json')
        as Map<String, dynamic>;
    final difficulties = data['difficulties'] as Map<String, dynamic>;
    setState(() {
      _easy = [
        ...(difficulties['easy'] as List)
            .map((e) => SpyWord.fromJson(e as Map<String, dynamic>)),
      ];
      _medium = [
        ...(difficulties['medium'] as List)
            .map((e) => SpyWord.fromJson(e as Map<String, dynamic>)),
      ];
      _hard = [
        ...(difficulties['hard'] as List)
            .map((e) => SpyWord.fromJson(e as Map<String, dynamic>)),
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
        SpyCardAssign(
          isSpy: true,
          word: word,
          category: word.category,
        ),
      for (var i = spies; i < total; i++)
        SpyCardAssign(
          isSpy: false,
          word: word,
          category: word.category,
        ),
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
          child: CircularProgressIndicator(color: AppColors.purple),
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
      trailing: HelpTrailing(
        onPressed: () => _openHelp(context),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _setupSection(
              icon: Icons.groups_rounded,
              title: 'تعداد کل بازیکن‌ها',
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
            const SizedBox(height: 14),
            _setupSection(
              icon: Icons.visibility_off_rounded,
              title: 'تعداد جاسوس‌ها',
              child: Center(
                child: NumberStepper(
                  value: _spyCount,
                  min: 1,
                  max: _playerCount ~/ 2,
                  onChanged: (v) => setState(() => _spyCount = v),
                ),
              ),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            DarkCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: SwitchListTile(
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.purple,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                title: const Text(
                  'آیا جاسوس هم کلمه راهنما داشته باشد؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'اگر روشن باشد، جاسوس فقط دسته‌بندی کلمه را می‌بیند',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.faintText, fontSize: 11),
                ),
                value: _spyHasHint,
                onChanged: (v) => setState(() => _spyHasHint = v),
              ),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 24),
            GlowButton(
              label: 'شروع بازی',
              icon: Icons.play_arrow_rounded,
              onPressed: _startGame,
            ),
            const SizedBox(height: 12),
            GlowButton(
              label: 'راهنمای بازی',
              icon: Icons.menu_book_rounded,
              filled: false,
              color: AppColors.accent,
              onPressed: () => _openHelp(context),
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
            ? AppColors.purple.withValues(alpha: 0.35)
            : AppColors.card;
      }),
      foregroundColor:
          WidgetStateProperty.all(Colors.white),
      side: WidgetStateProperty.all(
        BorderSide(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: AppColors.accent, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            ? 'تو جاسوسی! فقط دسته‌بندی را می‌دانی، نه خود کلمه. 🤫'
            : 'تو جاسوسی! کلمه‌ی اصلی را نمی‌دانی. وظیفه‌ی تو مخفی ماندن است. 🤫')
        : 'کلمه‌ی اصلی را می‌بینی. سعی کن بدون لو دادن کلمه، زرنگ باشی!';

    return GameShell(
      title: 'کارت نفر ${_currentRevealIndex + 1}',
      subtitle: 'از $total نفر',
      child: Column(
        children: [
          // نواری که نشان می‌دهد چند نفر دیده‌اند
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              textDirection: TextDirection.rtl,
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
                        ? AppColors.purple
                        : Colors.white.withValues(alpha: 0.10),
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
                      color: AppColors.mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 28),
                  GlowButton(
                    label: _currentRevealIndex == total - 1
                        ? 'همه دیدند · شروع تایمر ⏳'
                        : 'دیدم · نفر بعدی',
                    icon: _currentRevealIndex == total - 1
                        ? Icons.timer_rounded
                        : Icons.arrow_back_rounded,
                    color: _currentRevealIndex == total - 1
                        ? AppColors.green
                        : AppColors.purple,
                    onPressed: () {
                      setState(() => _currentRevealIndex += 1);
                      if (_currentRevealIndex == total) {
                        _startTimer();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resetPlay,
                    child: const Text(
                      'لغو و بازگشت به تنظیمات',
                      style: TextStyle(color: AppColors.faintText),
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
      subtitle: 'همه کارت‌ها دیده شد · کلمه را لو ندهید',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'حالا هیجان شروع می‌شود! بقیه باید جاسوس را پیدا کنند. 🕵️',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 230,
            height: 230,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3),
                width: 2,
              ),
              color: AppColors.card.withValues(alpha: 0.6),
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
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '⏳',
                      style: TextStyle(fontSize: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$mm:$ss',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'زمان مانده',
                      style: TextStyle(color: AppColors.faintText, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'اگر جاسوس رای آورد، او برنده است!\nاگر مردم او را پیدا کردند، شما برنده‌اید!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.faintText, fontSize: 13, height: 1.6),
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

  // ============================================================
  // پایان بازی
  // ============================================================

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
                color: AppColors.orange.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                ),
              ),
              child: const Center(
                child: Text('⏰', style: TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'زمان بحث تمام شد!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'حالا گروه رای بدهد: کدام نفر جاسوس بود؟\nکلمه‌ی واقعی: $_secretWord',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 14,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 30),
            GlowButton(
              label: 'بازی مجدد با همین تنظیمات 🔁',
              icon: Icons.replay_rounded,
              color: AppColors.green,
              onPressed: _playAgain,
            ),
            const SizedBox(height: 12),
            GlowButton(
              label: 'رفتن به تنظیمات بازی',
              icon: Icons.tune_rounded,
              filled: false,
              onPressed: _backToSetup,
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
            'همه دور هم می‌نشینند و تعداد نفرات و جاسوس‌ها مشخص می‌شود.',
            'یک کلمه به صورت تصادفی انتخاب و به همه نشان داده می‌شود؛ فقط جاسوس کلمه را نمی‌داند (یا فقط دسته‌بندی را می‌داند).',
            'گوشی را نفر به نفر بدهید. هر کس کارت خودش را ببیند و بعد نفر بعدی را صدا بزند.',
            'بعد از دیدن همه‌ی کارت‌ها، تایمر شروع و گفتگو آغاز می‌شود.',
            'بازیکن‌ها با پرسیدن سوال و استدلال باید جاسوس را پیدا کنند و جاسوس هم باید طوری رفتار کند که لو نرود.',
            'وقتی زمان تمام شد، گروه به جاسوس (یا جاسوس‌ها) رای می‌دهد. اگر پیدا شود، مردم برنده‌اند و اگر نه، جاسوس برنده است!',
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF29205D), Color(0xFF19143B)],
        ),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}