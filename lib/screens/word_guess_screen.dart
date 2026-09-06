import 'dart:async';

import 'package:flutter/material.dart';

import '../shared.dart';

// ============================================================
// صفحه‌ی اصلی بازی حدس کلمه
// ============================================================

class WordGuessScreen extends StatefulWidget {
  const WordGuessScreen({super.key});

  @override
  State<WordGuessScreen> createState() => _WordGuessScreenState();
}

enum _WStage { setup, countdown, playing, roundEnd, result }

class _WordGuessScreenState extends State<WordGuessScreen> {
  _WStage _stage = _WStage.setup;

  List<TextEditingController> _playerControllers = [];
  String _difficulty = 'easy';
  int _roundSeconds = 120;

  bool _dataLoaded = false;
  Map<String, List<String>> _wordPool = {};

  int _currentPlayer = 0;
  List<String> _roundQueue = [];
  int _queueIndex = 0;
  String _currentWord = '';
  int _correctCount = 0;
  int _wrongCount = 0;
  List<int> _scores = [];

  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _playerControllers = [TextEditingController(text: 'شخص اول')];
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _playerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await JsonLoader.load(
      'assets/data/word_guess_words.json',
    ) as Map<String, dynamic>;
    final d = data['difficulties'] as Map<String, dynamic>;
    setState(() {
      _wordPool = {
        'easy': (d['easy'] as List).cast<String>(),
        'medium': (d['medium'] as List).cast<String>(),
        'hard': (d['hard'] as List).cast<String>(),
      };
      _dataLoaded = true;
    });
  }

  void _addPlayer() {
    setState(() {
      _playerControllers.add(
        TextEditingController(text: 'شخص ${_playerControllers.length + 1}'),
      );
    });
  }

  void _removePlayer(int index) {
    if (_playerControllers.length <= 1) return;
    setState(() {
      _playerControllers.removeAt(index).dispose();
    });
  }

  String _playerName(int i) {
    final t = _playerControllers[i].text.trim();
    return t.isEmpty ? 'شخص ${i + 1}' : t;
  }

  void _startRound(int playerIndex) {
    final pool = (_wordPool[_difficulty] ?? _wordPool['easy']!).toList();
    setState(() {
      _currentPlayer = playerIndex;
      _roundQueue = shuffled(pool);
      _queueIndex = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _tick = 5;
      _stage = _WStage.countdown;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _tick -= 1);
      if (_tick <= 0) {
        t.cancel();
        _beginPlaying();
      }
    });
  }

  void _beginPlaying() {
    setState(() {
      _currentWord = _roundQueue[_queueIndex % _roundQueue.length];
      _tick = _roundSeconds;
      _stage = _WStage.playing;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_tick <= 1) {
        t.cancel();
        _finishPlayer();
      } else {
        setState(() => _tick -= 1);
      }
    });
  }

  void _nextWord(bool correct) {
    setState(() {
      if (correct) {
        _correctCount += 1;
      } else {
        _wrongCount += 1;
      }
      _queueIndex += 1;
      _currentWord = _roundQueue[_queueIndex % _roundQueue.length];
    });
  }

  void _finishPlayer() {
    _timer?.cancel();
    setState(() {
      _currentWord = '';
      _stage = _WStage.roundEnd;
    });
  }

  void _confirmedFinish() {
    setState(() {
      _scores.add(_correctCount);
    });
    if (_currentPlayer + 1 < _playerControllers.length) {
      _startRound(_currentPlayer + 1);
    } else {
      setState(() => _stage = _WStage.result);
    }
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _scores = [];
      _stage = _WStage.setup;
      _currentPlayer = 0;
      _currentWord = '';
      _roundQueue = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const GameShell(
        title: 'حدس کلمه',
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    switch (_stage) {
      case _WStage.setup:
        return _buildSetup();
      case _WStage.countdown:
        return _buildCountdown();
      case _WStage.playing:
        return _buildPlaying();
      case _WStage.roundEnd:
        return _buildRoundEnd();
      case _WStage.result:
        return _buildResult();
    }
  }

  // ============================================================
  // تنظیمات
  // ============================================================

  Widget _buildSetup() {
    return GameShell(
      title: 'حدس کلمه',
      subtitle: 'کلمه رو حدس بزن! 🤔',
      trailing: HelpTrailing(onPressed: () => _openHelp(context)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          DarkCard(
            padding: const EdgeInsets.all(AppTheme.spacing14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: AppTheme.primary,
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'شخص‌ها',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                ...List.generate(_playerControllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _playerControllers[i],
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecoration(),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removePlayer(i),
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),
                AnimatedTapScale(
                  onTap: _addPlayer,
                  child: const GlowButton(
                    label: 'افزودن شخص',
                    icon: Icons.person_add_alt_1_rounded,
                    height: 48,
                    filled: false,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DarkCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.equalizer_rounded,
                      color: AppTheme.primary,
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سختی کلمات',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
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
              ],
            ),
          ),
          const SizedBox(height: 14),
          DarkCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: AppTheme.primary,
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'زمان هر نفر',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 60, label: Text('۱ دقیقه')),
                    ButtonSegment(value: 120, label: Text('۲ دقیقه')),
                    ButtonSegment(value: 180, label: Text('۳ دقیقه')),
                  ],
                  selected: {_roundSeconds},
                  style: _segmentStyle(),
                  onSelectionChanged: (s) =>
                      setState(() => _roundSeconds = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AnimatedTapScale(
            onTap: () => _startRound(0),
            child: const GlowButton(
              label: 'شروع بازی — نفر اول',
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // شمارش معکوس
  // ============================================================

  Widget _buildCountdown() {
    return GameShell(
      title: 'آماده؟ ${_playerName(_currentPlayer)}!',
      subtitle: 'بعد از شمارش، کلمه را روی پیشانی بگیر',
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) {
            return ScaleTransition(scale: anim, child: child);
          },
          child: Text(
            '$_tick',
            key: ValueKey(_tick),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 110,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // مرحله بازی
  // ============================================================

  Widget _buildPlaying() {
    final mm = (_tick ~/ 60).toString().padLeft(2, '0');
    final ss = (_tick % 60).toString().padLeft(2, '0');

    return GameShell(
      title: '${_playerName(_currentPlayer)} 🤸',
      subtitle: 'زمان باقی‌مانده $mm:$ss',
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 26),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'این کلمه را دیگران ببینند، نه حدس‌زن! 🙈',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    _currentWord,
                    key: ValueKey(_currentWord),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Row(
              children: [
                _counterBox(
                  icon: Icons.check_circle_rounded,
                  value: _correctCount,
                  label: 'درست',
                  color: AppTheme.success,
                ),
                const SizedBox(width: 10),
                _counterBox(
                  icon: Icons.cancel_rounded,
                  value: _wrongCount,
                  label: 'اشتباه',
                  color: AppTheme.mafiaRed,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                const Text(
                  'حدس‌زن تلفن را روی پیشانی‌اش گذاشته و به صفحه نگاه نمی‌کند.\nراهنمایی‌کننده‌ها کلمه را می‌خوانند و بدون گفتن کلمه راهنمایی می‌کنند.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedTapScale(
                        onTap: () => _nextWord(false),
                        child: const GlowButton(
                          label: 'اشتباه ✗',
                          icon: Icons.close_rounded,
                          height: 58,
                          filled: false,
                          color: AppTheme.mafiaRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedTapScale(
                        onTap: () => _nextWord(true),
                        child: const GlowButton(
                          label: 'درست ✓',
                          icon: Icons.check_rounded,
                          height: 58,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterBox({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // پایان دور یک نفر
  // ============================================================

  Widget _buildRoundEnd() {
    final last = _currentPlayer + 1 >= _playerControllers.length;
    return GameShell(
      title: 'زمان ${_playerName(_currentPlayer)} تمام شد! ⏰',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_correctCount',
                    style: const TextStyle(
                      color: AppTheme.success,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'کلمه درست',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedTapScale(
              onTap: _confirmedFinish,
              child: GlowButton(
                label: last
                    ? 'مشاهده نتایج نهایی 🏆'
                    : 'نفر بعدی: ${_playerName(_currentPlayer + 1)}',
                icon: last
                    ? Icons.emoji_events_rounded
                    : Icons.arrow_back_rounded,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // نتایج
  // ============================================================

  Widget _buildResult() {
    final best = _scores.isEmpty ? 0 : _scores.reduce((a, b) => a > b ? a : b);
    final order = List.generate(_scores.length, (i) => i)
      ..sort((a, b) => _scores[b].compareTo(_scores[a]));

    return GameShell(
      title: 'نتایج نهایی 🏁',
      subtitle: 'تعداد حدس‌های درست',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          for (var place = 0; place < order.length; place++) ...[
            DarkCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Text(
                    place == 0 && best > 0
                        ? '🥇'
                        : (place == 1 && best > 0
                              ? '🥈'
                              : (place == 2 && best > 0
                                    ? '🥉'
                                    : '${place + 1}')),
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _playerName(order[place]),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppTheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      '${_scores[order[place]]} کلمه',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AnimatedTapScale(
            onTap: _resetGame,
            child: const GlowButton(
              label: 'بازی جدید',
              icon: Icons.replay_rounded,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ابزارها
  // ============================================================

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.primary),
      ),
      hintText: 'نام',
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
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

  void _openHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpPage(
          title: 'حدس کلمه',
          icon: Icons.question_mark_rounded,
          steps: [
            'شخص‌ها را اضافه کنید و سختی کلمات را انتخاب کنید؛ به هر نفر ۲ دقیقه فرصت می‌رسد.',
            'روی «شروع» بزنید؛ بعد از ۵ ثانیه اولین کلمه نمایش داده می‌شود.',
            'حدس‌زن باید خیلی سریع گوشی را روی پیشانی‌اش بگذارد تا کلمه را نبیند.',
            'بقیه باید بدون گفتن خود کلمه یا اشاره مستقیم، حدس‌زن را راهنمایی کنند.',
            'اگر درست حدس زد، یار راهنما دکمه‌ی «درست ✓» را بزند تا کلمه‌ی بعدی بیاید؛ اگر اشتباه بود «اشتباه ✗».',
            'بعد از دو دقیقه نوبت فرد بعدی است و در پایان، نتیجه‌ی همه بر اساس حدس‌های درست مشخص می‌شود!',
          ],
        ),
      ),
    );
  }
}
