import 'dart:async';

import 'package:flutter/material.dart';

import '../shared.dart';

// ============================================================
// مدل‌های پانتومیم
// ============================================================

class PantomimeWord {
  final String word;
  final int points;

  const PantomimeWord({required this.word, required this.points});

  factory PantomimeWord.fromJson(Map<String, dynamic> json) {
    return PantomimeWord(
      word: json['word'] as String,
      points: (json['points'] as num?)?.toInt() ?? 5,
    );
  }
}

class PantomimeCategory {
  final String name;
  final String emoji;
  final Color color;
  final List<PantomimeWord> words;

  const PantomimeCategory({
    required this.name,
    required this.emoji,
    required this.color,
    required this.words,
  });

  factory PantomimeCategory.fromJson(Map<String, dynamic> json) {
    return PantomimeCategory(
      name: json['name'] as String,
      emoji: (json['emoji'] as String?) ?? '🎭',
      color: AppTint.rgbaHex((json['color'] as String?) ?? '#6C5CE7'),
      words: [
        ...(json['words'] as List).map(
          (e) => PantomimeWord.fromJson(e as Map<String, dynamic>),
        ),
      ],
    );
  }
}

class PantomimeProverb {
  final String text;
  final int points;

  const PantomimeProverb({required this.text, required this.points});

  factory PantomimeProverb.fromJson(Map<String, dynamic> json) {
    return PantomimeProverb(
      text: json['text'] as String,
      points: (json['points'] as num?)?.toInt() ?? 30,
    );
  }
}

class _RoundPick {
  final String label; // کلمه یا ضرب المثل
  final int points;
  final bool isProverb;

  const _RoundPick({
    required this.label,
    required this.points,
    required this.isProverb,
  });
}

// ============================================================
// صفحه اصلی پانتومیم
// ============================================================

class PantomimeScreen extends StatefulWidget {
  const PantomimeScreen({super.key});

  @override
  State<PantomimeScreen> createState() => _PantomimeScreenState();
}

enum _PStage { setup, pick, preview, judge, result }

class _PantomimeScreenState extends State<PantomimeScreen> {
  _PStage _stage = _PStage.setup;

  List<TextEditingController> _teamControllers = [];
  List<int> _scores = [];
  List<int> _roundsDone = [];
  int _roundsPerTeam = 5;

  bool _dataLoaded = false;
  List<PantomimeCategory> _categories = [];
  List<PantomimeProverb> _proverbs = [];
  final Set<String> _usedPicks = {};

  int _currentTeam = 0;
  _RoundPick? _pick;

  Timer? _timer;
  int _elapsedSeconds = 0;
  int _faultCount = 0;

  @override
  void initState() {
    super.initState();
    _teamControllers = [
      TextEditingController(text: 'گروه اول'),
      TextEditingController(text: 'گروه دوم'),
    ];
    _scores = List.filled(2, 0);
    _roundsDone = List.filled(2, 0);
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _teamControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await JsonLoader.load(
      'assets/data/pantomime_categories.json',
    ) as Map<String, dynamic>;
    setState(() {
      _categories = [
        ...(data['categories'] as List).map(
          (e) => PantomimeCategory.fromJson(e as Map<String, dynamic>),
        ),
      ];
      _proverbs = [
        ...(data['proverbs'] as List).map(
          (e) => PantomimeProverb.fromJson(e as Map<String, dynamic>),
        ),
      ];
      _dataLoaded = true;
    });
  }

  void _addTeam() {
    final label = 'گروه ${_teamControllers.length + 1}';
    setState(() {
      _teamControllers.add(TextEditingController(text: label));
      _scores.add(0);
      _roundsDone.add(0);
    });
  }

  void _removeTeam(int index) {
    if (_teamControllers.length <= 2) return;
    setState(() {
      _teamControllers.removeAt(index).dispose();
      _scores.removeAt(index);
      _roundsDone.removeAt(index);
    });
  }

  void _startGame() {
    final names = _teamControllers
        .map((c) => c.text.trim().isEmpty ? 'گروه' : c.text.trim())
        .toList();
    for (var i = 0; i < _teamControllers.length; i++) {
      if (_teamControllers[i].text.trim().isEmpty) {
        _teamControllers[i].text = names[i];
      }
    }
    setState(() {
      _currentTeam = 0;
      _roundsDone = List.filled(_teamControllers.length, 0);
      _usedPicks.clear();
      _stage = _PStage.pick;
    });
  }

  int? _nextTeam({int after = 0}) {
    for (var i = 1; i <= _teamControllers.length; i++) {
      final idx = (after + i) % _teamControllers.length;
      if (_roundsDone[idx] < _roundsPerTeam) return idx;
    }
    return null;
  }

  String _teamName(int i) {
    final t = _teamControllers[i].text.trim();
    return t.isEmpty ? 'گروه ${i + 1}' : t;
  }

  void _selectWord(PantomimeCategory cat, PantomimeWord word) {
    _usedPicks.add('cat|${cat.name}|${word.word}');
    setState(() {
      _pick = _RoundPick(
        label: word.word,
        points: word.points,
        isProverb: false,
      );
      _stage = _PStage.preview;
    });
  }

  void _selectProverb(int points) {
    final candidates = _proverbs
        .where(
          (p) => p.points == points && !_usedPicks.contains('prov|${p.text}'),
        )
        .toList();
    final target = (candidates.isEmpty
        ? _proverbs.where((p) => p.points == points).toList()
        : candidates);
    final proverb = target.isEmpty
        ? _proverbs.first
        : target[randomInt(target.length)];
    _usedPicks.add('prov|${proverb.text}');
    setState(() {
      _pick = _RoundPick(
        label: proverb.text,
        points: proverb.points,
        isProverb: true,
      );
      _stage = _PStage.preview;
    });
  }

  void _startJudge() {
    setState(() {
      _faultCount = 0;
      _elapsedSeconds = 0;
      _stage = _PStage.judge;
    });
  }

  void _beginTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_elapsedSeconds >= 300) {
        t.cancel();
        return;
      }
      setState(() => _elapsedSeconds += 1);
    });
  }

  void _toggleTimer() {
    if (_timer == null || !_timer!.isActive) {
      _beginTimer();
    } else {
      _timer!.cancel();
      setState(() {});
    }
  }

  int get _faultPenalty {
    const table = [0, 3, 5, 10];
    return _faultCount <= 0 ? 0 : table[_faultCount > 3 ? 3 : _faultCount];
  }

  int get _timeBonus {
    final remaining = 300 - _elapsedSeconds;
    return (remaining > 0) ? remaining ~/ 60 : 0;
  }

  int get _roundScore {
    if (_pick == null) return 0;
    final v = _pick!.points + _timeBonus - _faultPenalty;
    if (v < 0) return 0;
    if (v > 999) return 999;
    return v;
  }

  void _recordRound() {
    _timer?.cancel();
    final score = _roundScore;
    setState(() {
      _scores[_currentTeam] += score;
      _roundsDone[_currentTeam] += 1;
      _pick = null;
    });

    final next = _nextTeam(after: _currentTeam);
    if (next == null) {
      setState(() => _stage = _PStage.result);
    } else {
      setState(() {
        _currentTeam = next;
        _stage = _PStage.pick;
      });
    }
  }

  void _skipRound() {
    _timer?.cancel();
    setState(() {
      _roundsDone[_currentTeam] += 1;
      _pick = null;
    });
    final next = _nextTeam(after: _currentTeam);
    if (next == null) {
      setState(() => _stage = _PStage.result);
    } else {
      setState(() {
        _currentTeam = next;
        _stage = _PStage.pick;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const GameShell(
        title: 'پانتومیم',
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    switch (_stage) {
      case _PStage.setup:
        return _buildSetup();
      case _PStage.pick:
        return _buildPick();
      case _PStage.preview:
        return _buildPreview();
      case _PStage.judge:
        return _buildJudge();
      case _PStage.result:
        return _buildResult();
    }
  }

  // ============================================================
  // صفحه تنظیمات
  // ============================================================

  Widget _buildSetup() {
    return GameShell(
      title: 'پانتومیم',
      subtitle: 'بگو، اما با حرف زدن نه! 🤐',
      trailing: HelpTrailing(onPressed: () => _openHelp(context)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          DarkCard(
            padding: const EdgeInsets.all(AppTheme.spacing14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: AppTheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        'گروه‌های بازی (${_teamControllers.length} گروه)',
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
                const SizedBox(height: AppTheme.spacing2),
                ...List.generate(_teamControllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _teamColor(i).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: _teamColor(i),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing10),
                        Expanded(
                          child: TextField(
                            controller: _teamControllers[i],
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecoration(),
                          ),
                        ),
                        if (_teamControllers.length > 2)
                          IconButton(
                            onPressed: () => _removeTeam(i),
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppTheme.spacing14),
                AnimatedTapScale(
                  onTap: _addTeam,
                  child: const GlowButton(
                    label: 'افزودن گروه',
                    icon: Icons.add_rounded,
                    height: 48,
                    filled: false,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing14),
          DarkCard(
            padding: const EdgeInsets.all(AppTheme.spacing14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.loop_rounded, color: AppTheme.primary, size: 19),
                    SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        'تعداد پانتومیم برای هر گروه',
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
                const SizedBox(height: AppTheme.spacing12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 3, label: Text('۳ دور')),
                    ButtonSegment(value: 5, label: Text('۵ دور')),
                    ButtonSegment(value: 7, label: Text('۷ دور')),
                  ],
                  selected: {_roundsPerTeam},
                  style: _segmentStyle(),
                  onSelectionChanged: (s) =>
                      setState(() => _roundsPerTeam = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          AnimatedTapScale(
            onTap: _startGame,
            child: const GlowButton(
              label: 'شروع بازی با گروه اول',
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Color _teamColor(int i) {
    const palette = [
      AppTheme.primary,
      AppTheme.citizenGreen,
      AppTheme.warning,
      AppTheme.mafiaRed,
      Color(0xFF8A2BE2),
      Color(0xFF1E90FF),
    ];
    return palette[i % palette.length];
  }

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
      hintText: 'نام گروه',
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

  // ============================================================
  // صفحه انتخاب کلمه
  // ============================================================

  Widget _buildPick() {
    final progress = _roundsDone[_currentTeam];
    return GameShell(
      title: 'نوبت ${_teamName(_currentTeam)} 🎭',
      subtitle:
          'دور ${progress + 1} از $_roundsPerTeam · ${_currentTeam + 1} از ${_teamControllers.length}',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: AppTheme.border),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusMedium)),
                  color: AppTheme.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: 'دسته‌بندی‌ها'),
                  Tab(text: 'ضرب المثل'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [_buildCategoriesTab(), _buildProverbsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final cat = _categories[i];
        return AnimatedTapScale(
          onTap: () => _openCategory(i),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              color: cat.color.withValues(alpha: 0.06),
              border: Border.all(color: cat.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  cat.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCategory(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CategoryWordsScreen(
          category: _categories[index],
          usedPicks: _usedPicks,
          selectedColor: _teamColor(_currentTeam),
          onSelect: (word) => _selectWord(_categories[index], word),
        ),
      ),
    );
  }

  Widget _buildProverbsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'ضرب المثل را انتخاب کن؛ هرچه امتیازش بیشتر، اجرای سخت‌تر!',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.spacing10),
        for (final pts in const [30, 50, 100]) ...[
          _ProverbCard(
            points: pts,
            color: _teamColor(_currentTeam),
            onTap: () => _selectProverb(pts),
          ),
          const SizedBox(height: AppTheme.spacing10),
        ],
      ],
    );
  }

  // ============================================================
  // صفحه مشاهده کلمه (بازیگر)
  // ============================================================

  Widget _buildPreview() {
    final pick = _pick;
    if (pick == null) return const SizedBox.shrink();
    return GameShell(
      title: 'کلمه‌ی ${_teamName(_currentTeam)}',
      subtitle: pick.isProverb
          ? 'ضرب المثل · ${pick.points} امتیازی'
          : '${pick.points} امتیازی',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'فقط تو ببین! اجراکننده باید این را نشان بدهد 🤫',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                border: Border.all(
                  color: _teamColor(_currentTeam).withValues(alpha: 0.4),
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
              child: Text(
                pick.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing26),
            const Text(
              '۱. کلمه را یاد بگیر.\n۲. گوشی را به داور (یار گروه حریف) بده.\n۳. داور تایمر ۵ دقیقه را شروع کند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.9,
              ),
            ),
            const SizedBox(height: AppTheme.spacing22),
            AnimatedTapScale(
              onTap: _startJudge,
              child: GlowButton(
                label: 'یادم آمد · گوشی را به داور بده',
                icon: Icons.arrow_back_rounded,
                color: _teamColor(_currentTeam),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // صفحه داوری
  // ============================================================

  Widget _buildJudge() {
    final pick = _pick;
    final remaining = 300 - _elapsedSeconds;
    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');
    final running = _timer?.isActive ?? false;

    return GameShell(
      title: 'داور: ${_teamName(_currentTeam)} 🧑‍⚖️',
      subtitle: 'گوشی به دست داور است',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  pick?.label ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing6),
                const Text(
                  'داور برای صحت اجرا این کلمه را می‌بیند',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing22),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
              border: Border.all(
                color: running
                    ? AppTheme.citizenGreen.withValues(alpha: 0.5)
                    : AppTheme.border,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$mm:$ss',
                  style: TextStyle(
                    color: running ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'از ۵ دقیقه',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: AppTheme.spacing10),
                GlowButton(
                  label: running ? 'توقف تایمر ⏸️' : 'شروع تایمر ۵ دقیقه ▶️',
                  icon: running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  height: 48,
                  filled: false,
                  color: running ? AppTheme.warning : AppTheme.success,
                  onPressed: _toggleTimer,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing14),
          DarkCard(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'خطاهای اجراکننده',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing10),
                Row(
                  children: [
                    for (var i = 1; i <= 3; i++) ...[
                      Expanded(
                        child: InkWell(
                          onTap: _faultCount >= i
                              ? null
                              : () => setState(() => _faultCount = i),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              color: i <= _faultCount
                                  ? AppTheme.mafiaRed.withValues(alpha: 0.12)
                                  : AppTheme.surfaceVariant,
                              border: Border.all(
                                color: i <= _faultCount
                                    ? AppTheme.mafiaRed.withValues(alpha: 0.5)
                                    : AppTheme.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'خطای $i',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_faultRow(i)} امتیاز',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (i < 3) const SizedBox(width: AppTheme.spacing8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing14),
          DarkCard(
            padding: const EdgeInsets.all(AppTheme.spacing14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'امتیاز کلمه',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      '+${pick?.points ?? 0}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'پاداش زمان باقی‌مانده',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      '+$_timeBonus',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'کسر خطا',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      '-$_faultPenalty',
                      style: const TextStyle(
                        color: AppTheme.mafiaRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.divider, height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'امتیاز این دور برای ${_teamName(_currentTeam)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$_roundScore',
                      style: TextStyle(
                        color: _teamColor(_currentTeam),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          AnimatedTapScale(
            onTap: _recordRound,
            child: const GlowButton(
              label: 'درست پاسخ داد ✅ و ثبت امتیاز',
              icon: Icons.check_circle_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          AnimatedTapScale(
            onTap: _skipRound,
            child: const GlowButton(
              label: 'انصراف از این دور (صفر امتیاز)',
              icon: Icons.close_rounded,
              filled: false,
              color: AppTheme.mafiaRed,
            ),
          ),
        ],
      ),
    );
  }

  int _faultRow(int i) {
    switch (i) {
      case 1:
        return 3;
      case 2:
        return 5;
      default:
        return 10;
    }
  }

  // ============================================================
  // صفحه نتیجه
  // ============================================================

  Widget _buildResult() {
    final maxScore = _scores.reduce((a, b) => a > b ? a : b);
    final winners = <int>[];
    for (var i = 0; i < _scores.length; i++) {
      if (_scores[i] == maxScore && maxScore > 0) winners.add(i);
    }

    return GameShell(
      title: 'نتایج بازی 🏆',
      subtitle: 'مجموع امتیاز $_roundsPerTeam دور برای هر گروه',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Text(
            winners.isNotEmpty
                ? winners.length == 1
                      ? 'گروه ${_teamName(winners.first)} برنده شد! 🎉'
                      : 'گروه‌های ${winners.map(_teamName).join(' و ')} مساوی شدند! 🤝'
                : 'امتیازی ثبت نشد!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          for (final p in _sortedTeamIndices()) ...[
            DarkCard(
              margin: const EdgeInsets.only(bottom: AppTheme.spacing10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _teamColor(p).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      p + 1 == winners.length && winners.length == 1
                          ? '👑'
                          : '${p + 1}',
                      style: TextStyle(
                        color: _teamColor(p),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                _teamName(p),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (winners.contains(p)) ...[
                              const SizedBox(width: 6),
                              const Text('🏆'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_scores[p]} امتیاز',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: _teamColor(p),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing20),
          AnimatedTapScale(
            onTap: () {
              setState(() {
                _stage = _PStage.setup;
                _scores = List.filled(_teamControllers.length, 0);
                _roundsDone = List.filled(_teamControllers.length, 0);
              });
            },
            child: const GlowButton(
              label: 'بازی جدید',
              icon: Icons.replay_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: AppTheme.spacing10),
          AnimatedTapScale(
            onTap: _startGame,
            child: const GlowButton(
              label: 'ادامه با همین تیم‌ها',
              icon: Icons.play_arrow_rounded,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  List<int> _sortedTeamIndices() {
    final indices = List.generate(_scores.length, (i) => i);
    indices.sort((a, b) => _scores[b].compareTo(_scores[a]));
    return indices;
  }

  void _openHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpPage(
          title: 'پانتومیم',
          icon: Icons.theater_comedy_rounded,
          steps: [
            'گروه‌ها را بسازید؛ بازی با گروه اول شروع می‌شود و به ترتیب نوبت به بقیه می‌رسد.',
            'در نوبت هر گروه، اجراکننده یک دسته‌بندی و کلمه (یا ضرب المثل) را انتخاب می‌کند.',
            'با نظارت یار گروه حریف، دکمه‌ی دیدن کلمه را بزنید و کلمه را یاد بگیرید.',
            'گوشی را به داور (یار حریف) بدهید؛ داور تایمر ۵ دقیقه را شروع می‌کند.',
            'اجراکننده فقط با اشاره و حرکت کلمه را نشان می‌دهد؛ صحبت کردن ممنوع است.',
            'اگر گروهش حدس زد، داور «درست پاسخ داد» را می‌زند. امتیاز = امتیاز کلمه + پاداش زمان − کسر خطا.',
            'خطاها: بار اول ۳، بار دوم ۵ و بار سوم ۱۰ امتیاز کسر می‌شود.',
            'در پایان $_roundsPerTeam دور برای هر گروه، امتیازها جمع و تیم برنده مشخص می‌شود.',
          ],
        ),
      ),
    );
  }
}

// ============================================================
// صفحه انتخاب کلمه از یک دسته
// ============================================================

class _CategoryWordsScreen extends StatefulWidget {
  final PantomimeCategory category;
  final Set<String> usedPicks;
  final Color selectedColor;
  final ValueChanged<PantomimeWord> onSelect;

  const _CategoryWordsScreen({
    required this.category,
    required this.usedPicks,
    required this.selectedColor,
    required this.onSelect,
  });

  @override
  State<_CategoryWordsScreen> createState() => _CategoryWordsScreenState();
}

class _CategoryWordsScreenState extends State<_CategoryWordsScreen> {
  int? _pointsFilter;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.category.words
        .where((w) => _pointsFilter == null || w.points == _pointsFilter)
        .toList();

    return GameShell(
      title: widget.category.name,
      subtitle: '${widget.category.emoji} · انتخاب کلمه',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                for (final filter in const <int?>[null, 5, 10, 15]) ...[
                  _filterChip(
                    filter == null ? 'همه' : '$filter امتیازی',
                    _pointsFilter == filter,
                    () => setState(() => _pointsFilter = filter),
                  ),
                  const SizedBox(width: AppTheme.spacing6),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final w = filtered[i];
                final used = widget.usedPicks.contains(
                  'cat|${widget.category.name}|${w.word}',
                );
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    onTap: used
                        ? null
                        : () {
                            widget.onSelect(w);
                            Navigator.of(context).pop();
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacing10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        color: AppTheme.cardBg,
                        border: Border.all(
                          color: used
                              ? AppTheme.border
                              : widget.selectedColor.withValues(alpha: 0.3),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 16,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: widget.selectedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: Text(
                              '${w.points}',
                              style: TextStyle(
                                color: widget.selectedColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing10),
                          Expanded(
                            child: Text(
                              w.word,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (used)
                            const Text(
                              'استفاده شد ✅',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_left_rounded,
                              color: AppTheme.textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: selected
              ? widget.selectedColor.withValues(alpha: 0.12)
              : AppTheme.surfaceVariant,
          border: Border.all(
            color: selected
                ? widget.selectedColor
                : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? widget.selectedColor : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// کارت ضرب المثل
// ============================================================

class _ProverbCard extends StatelessWidget {
  final int points;
  final Color color;
  final VoidCallback onTap;

  const _ProverbCard({
    required this.points,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            color: AppTheme.cardBg,
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                points == 100 ? '🔥' : (points == 50 ? '⚡' : '📜'),
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ضرب المثل $points امتیازی',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'یک ضرب المثل تصادفی برای نشان دادن',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.casino_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
