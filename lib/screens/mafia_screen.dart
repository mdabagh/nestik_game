import 'package:flutter/material.dart';

import '../shared.dart';

// ============================================================
// مدل‌ها
// ============================================================

class MafiaRole {
  final String id;
  final String group;
  final String groupEmoji;
  final String name;
  final String emoji;
  final String description;
  final String help;

  const MafiaRole({
    required this.id,
    required this.group,
    required this.groupEmoji,
    required this.name,
    required this.emoji,
    required this.description,
    required this.help,
  });

  factory MafiaRole.fromJson(Map<String, dynamic> json) {
    return MafiaRole(
      id: json['id'] as String,
      group: json['group'] as String,
      groupEmoji: (json['groupEmoji'] as String?) ?? '🎭',
      name: json['name'] as String,
      emoji: (json['emoji'] as String?) ?? '🧑',
      description: json['description'] as String? ?? '',
      help: json['help'] as String? ?? '',
    );
  }

  bool get isMafia => group == 'مافیا';
}

class MafiaScenario {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final Map<int, List<String>> counts; // تعداد نفرات -> لیست نام نقش‌ها

  const MafiaScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.counts,
  });

  factory MafiaScenario.fromJson(Map<String, dynamic> json) {
    final countsRaw = json['counts'] as Map<String, dynamic>;
    final counts = <int, List<String>>{};
    countsRaw.forEach((key, value) {
      final v = value as Map<String, dynamic>;
      final citizens = (v['citizens'] as List).cast<String>();
      final mafia = (v['mafia'] as List).cast<String>();
      counts[int.parse(key)] = [...citizens, ...mafia];
    });
    return MafiaScenario(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      emoji: (json['emoji'] as String?) ?? '🏙️',
      color: AppTint.rgbaHex((json['color'] as String?) ?? '#6C4DFF'),
      counts: counts,
    );
  }

  List<int> get availableCounts =>
      counts.keys.toList()..sort((a, b) => a.compareTo(b));
}

// ============================================================
// صفحه اصلی مافیا
// ============================================================

class MafiaScreen extends StatefulWidget {
  const MafiaScreen({super.key});

  @override
  State<MafiaScreen> createState() => _MafiaScreenState();
}

class _MafiaScreenState extends State<MafiaScreen> {
  bool _dataLoaded = false;
  List<MafiaScenario> _scenarios = [];
  List<MafiaRole> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await JsonLoader.load('assets/data/mafia_scenarios.json')
        as Map<String, dynamic>;
    setState(() {
      _scenarios = [
        ...(data['scenarios'] as List)
            .map((e) => MafiaScenario.fromJson(e as Map<String, dynamic>)),
      ];
      _roles = [
        ...(data['roles'] as List)
            .map((e) => MafiaRole.fromJson(e as Map<String, dynamic>)),
      ];
      _dataLoaded = true;
    });
  }

  MafiaRole? _roleByName(String name) {
    for (final r in _roles) {
      if (r.name == name) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const GameShell(
        title: 'مافیا',
        child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    final citizens = _roles.where((r) => !r.isMafia).toList();
    final mafias = _roles.where((r) => r.isMafia).toList();

    return GameShell(
      title: 'بازی مافیا',
      subtitle: 'شهر در خواب است... 🌙',
      trailing: HelpTrailing(onPressed: () => _openHelp(context)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'انتخاب سناریو',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final s in _scenarios) ...[
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _MafiaCountScreen(
                    scenario: s,
                    roleByName: _roleByName,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: s.color.withValues(alpha: 0.12),
                  border: Border.all(color: s.color.withValues(alpha: 0.45)),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(s.emoji, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  s.name,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${s.availableCounts.first} تا ${s.availableCounts.last} نفر',
                                style: TextStyle(
                                  color: s.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.description,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded,
                        color: AppColors.faintText),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _MafiaCustomScreen(
                  roles: _roles,
                  roleByName: _roleByName,
                  citizens: citizens,
                  mafias: mafias,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF29205D), Color(0xFF19143B)],
                ),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'بازی سفارشی',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'خودت نقش‌ها را انتخاب کن؛ روی هر نقش بزن تا راهنما را ببینی',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded,
                      color: AppColors.faintText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HelpPage(
          title: 'مافیا',
          icon: Icons.person_rounded,
          steps: [
            'یک سناریو انتخاب کنید یا با «بازی سفارشی» نقش‌های دلخواه خودتان را بسازید.',
            'تعداد نفرات را وارد کنید؛ بر اساس سناریو، ترکیب شهروندها و مافیاها مشخص می‌شود.',
            'لیست کارت‌ها را ببینید و «شروع توزیع» را بزنید. همه‌ی کارت‌ها مخفی می‌شوند.',
            'گاد گوشی را به نفر اول می‌دهد؛ یک شماره انتخاب می‌شود و کارت آن نفر رندوم ظاهر می‌شود.',
            'رنگ کارت‌ها یکسان است تا با نگاه شدن از روی عینک یا انعکاس، کسی لو نرود.',
            'بعد از دیدن کارت همه، وظیفه‌ی گاد با برنامه تمام می‌شود و بازی شب و روز آغاز می‌شود!',
          ],
        ),
      ),
    );
  }
}

// ============================================================
// انتخاب تعداد نفرات + پیش‌نمایش کارت‌ها
// ============================================================

class _MafiaCountScreen extends StatefulWidget {
  final MafiaScenario scenario;
  final MafiaRole? Function(String) roleByName;

  const _MafiaCountScreen({
    required this.scenario,
    required this.roleByName,
  });

  @override
  State<_MafiaCountScreen> createState() => _MafiaCountScreenState();
}

class _MafiaCountScreenState extends State<_MafiaCountScreen> {
  int? _selectedCount;
  List<MafiaRole>? _deckRoles;

  void _buildDeck(int count) {
    final names = widget.scenario.counts[count] ?? [];
    final roles = [
      for (final n in names)
        widget.roleByName(n) ??
            const MafiaRole(
              id: 'unknown',
              group: 'شهروند',
              groupEmoji: '🤝',
              name: 'شهروند',
              emoji: '🧑',
              description: '',
              help: '',
            ),
    ];
    setState(() {
      _selectedCount = count;
      _deckRoles = roles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    return GameShell(
      title: scenario.name,
      subtitle: scenario.description,
      child: _selectedCount == null || _deckRoles == null
          ? _buildCountPicker(scenario)
          : _buildDeckPreview(scenario),
    );
  }

  Widget _buildCountPicker(MafiaScenario scenario) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        DarkCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(scenario.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              const Text(
                'چند نفر بازی می‌کنید؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'گاد جدا از بازیکن‌هاست؛ تعداد را بدون گاد وارد کنید.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.faintText, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in scenario.availableCounts)
                    InkWell(
                      onTap: () => _buildDeck(c),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: scenario.color.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '$c',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlowButton(
          label: 'راهنمای بازی',
          icon: Icons.menu_book_rounded,
          filled: false,
          color: AppColors.accent,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpPage(
                  title: 'مافیا',
                  icon: Icons.person_rounded,
                  steps: [
                    'روز: همه بیدار می‌شوند؛ مافیا مثل شهروند رفتار می‌کند و بحث درباره‌ی اعدام می‌شود.',
                    'شب: مافیا بیدار می‌شوند و یک نفر را انتخاب می‌کنند؛ پزشک یک نفر را نجات می‌دهد.',
                    'کارآگاه هویت یک نفر را می‌پرسد؛ ریش سفید و شهردار نقش‌های ویژه‌ی خود را دارند.',
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeckPreview(MafiaScenario scenario) {
    final roles = _deckRoles!;
    final mafiaCount = roles.where((r) => r.isMafia).length;
    final citizenCount = roles.length - mafiaCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        DarkCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _statBox(
                  label: 'شهروند',
                  value: citizenCount,
                  color: AppColors.green,
                  emoji: '🤝',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: 'مافیا',
                  value: mafiaCount,
                  color: AppColors.red,
                  emoji: '🕶️',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            'لیست همه‌ی کارت‌ها (گاد ببیند)',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ..._roleDeckPreview(roles),
        const SizedBox(height: 16),
        GlowButton(
          label: 'شروع توزیع کارت‌ها 🃏',
          icon: Icons.deck_rounded,
          color: scenario.color,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => _MafiaDealScreen(
                  deck: roles,
                  scenarioName: scenario.name,
                  scenarioEmoji: scenario.emoji,
                  color: scenario.color,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() {
            _selectedCount = null;
            _deckRoles = null;
          }),
          child: const Text(
            'تغییر تعداد نفرات',
            style: TextStyle(color: AppColors.faintText),
          ),
        ),
      ],
    );
  }

  Widget _statBox({
    required String label,
    required int value,
    required Color color,
    required String emoji,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _roleDeckPreview(List<MafiaRole> roles) {
    final mafia = roles.where((r) => r.isMafia).toList();
    final citizens = roles.where((r) => !r.isMafia).toList();
    final sections = <(String, String, List<MafiaRole>)>[
      ('مافیا', '🕶️', mafia),
      ('شهروند', '🤝', citizens),
    ];

    final widgets = <Widget>[];
    for (final (title, emoji, list) in sections) {
      if (list.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Text(
            '$emoji $title (${list.length})',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      final counts = <String, int>{};
      for (final r in list) {
        counts[r.name] = (counts[r.name] ?? 0) + 1;
      }
      counts.forEach((name, count) {
        final role = widget.roleByName(name);
        widgets.add(
          InkWell(
            onTap: role == null
                ? null
                : () => _showRoleHelp(role),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.card,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text(role?.emoji ?? '🧑',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Text(
                      '$count عدد',
                      style: const TextStyle(
                        color: AppColors.faintText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.help_outline_rounded,
                      color: AppColors.faintText, size: 18),
                ],
              ),
            ),
          ),
        );
      });
    }
    return widgets;
  }

  void _showRoleHelp(MafiaRole role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (role.isMafia ? AppColors.red : AppColors.green)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(role.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          role.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${role.groupEmoji} گروه ${role.group}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: role.isMafia
                                ? AppColors.red
                                : AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                role.help,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// توزیع و مشاهده‌ی کارت‌ها (گاد)
// ============================================================

class _MafiaDealScreen extends StatefulWidget {
  final List<MafiaRole> deck;
  final String scenarioName;
  final String scenarioEmoji;
  final Color color;

  const _MafiaDealScreen({
    required this.deck,
    required this.scenarioName,
    required this.scenarioEmoji,
    required this.color,
  });

  @override
  State<_MafiaDealScreen> createState() => _MafiaDealScreenState();
}

class _MafiaDealScreenState extends State<_MafiaDealScreen> {
  late List<bool> _revealed;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _revealed = List.filled(widget.deck.length, false);
    _selected = null;
  }

  int get _revealedCount => _revealed.where((r) => r).length;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _buildCardView();
    }
    if (_revealedCount == widget.deck.length) {
      return _buildDone();
    }
    return _buildGrid();
  }

  Widget _buildGrid() {
    return GameShell(
      title: 'توزیع کارت‌ها 🃏',
      subtitle: '$_revealedCount از ${widget.deck.length} نفر دیده‌اند',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: DarkCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: const Text(
                'گاد: گوشی را به نفر اول بده. یک شماره را انتخاب کن؛ فقط همان نفر کارتش را ببیند.\nمواظب باش بقیه نگاه نکنند!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: widget.deck.length,
              itemBuilder: (context, i) {
                final seen = _revealed[i];
                return InkWell(
                  onTap: seen ? null : () => setState(() => _selected = i),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF29205D), Color(0xFF19143B)],
                      ),
                      border: Border.all(
                        color: seen
                            ? Colors.white.withValues(alpha: 0.05)
                            : widget.color.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: seen
                          ? Text(roleOrTag(i),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ))
                          : Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
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

  String roleOrTag(int i) {
    final r = widget.deck[i];
    return _revealed[i] ? '${r.emoji}\n${r.name}' : '${i + 1}';
  }

  Widget _buildCardView() {
    final i = _selected!;
    final role = widget.deck[i];
    return GameShell(
      title: 'کارت نفر ${i + 1} 🎭',
      subtitle: 'فقط این نفر ببیند',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
        child: Column(
          children: [
            const Text(
              'رنگ کارت‌ها برای همه یکسان است تا از روی صفحه لو نرود 🔒',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF29205D), Color(0xFF19143B)],
                ),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.5),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.22),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Text(role.emoji, style: const TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    role.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${role.groupEmoji} گروه ${role.group}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: role.isMafia ? AppColors.red : AppColors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                children: [
                  Text(
                    '${_revealedCount + 1} از ${widget.deck.length} نفر دیده‌اند',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.faintText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlowButton(
                    label: _revealedCount + 1 == widget.deck.length
                        ? 'آخرین نفر · تمام! 🎉'
                        : 'دیدم · برگرد به فهرست نفرات',
                    icon: Icons.arrow_back_rounded,
                    color: _revealedCount + 1 == widget.deck.length
                        ? AppColors.green
                        : widget.color,
                    onPressed: () {
                      setState(() {
                        _revealed[i] = true;
                        _selected = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone() {
    return GameShell(
      title: 'توزیع تمام شد! 🎊',
      subtitle: widget.scenarioName,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.scenarioEmoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 18),
            const Text(
              'همه نقش خودشان را دیدند. حالا دیگر برنامه کاری برای گاد ندارد!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'گاد، حالا نقش اصلی تو شروع می‌شود:\n«شهر خواب است... 🌙»\nشب فرارسد، مافیا بیدار شوند!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 14,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 30),
            GlowButton(
              label: 'مشاهده‌ی دوباره‌ی کارت‌ها',
              icon: Icons.replay_rounded,
              filled: false,
              onPressed: () {
                setState(() {
                  _revealed = List.filled(widget.deck.length, false);
                  _selected = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// بازی سفارشی
// ============================================================

class _MafiaCustomScreen extends StatefulWidget {
  final List<MafiaRole> roles;
  final List<MafiaRole> citizens;
  final List<MafiaRole> mafias;
  final MafiaRole? Function(String) roleByName;

  const _MafiaCustomScreen({
    required this.roles,
    required this.citizens,
    required this.mafias,
    required this.roleByName,
  });

  @override
  State<_MafiaCustomScreen> createState() => _MafiaCustomScreenState();
}

class _MafiaCustomScreenState extends State<_MafiaCustomScreen> {
  int _playerCount = 8;
  final Map<String, int> _selection = {};

  int get _selectedTotal =>
      _selection.values.fold(0, (a, b) => a + b);

  int get _remainingSlots {
    final v = _playerCount - _selectedTotal;
    return v < 0 ? 0 : v;
  }

  void _toggleRole(MafiaRole role) {
    final current = _selection[role.id] ?? 0;
    if (current > 0) {
      setState(() => _selection[role.id] = current - 1);
    } else if (_selectedTotal < _playerCount) {
      setState(() => _selection[role.id] = 1);
    }
  }

  List<MafiaRole> _buildDeck() {
    final deck = <MafiaRole>[];
    for (final entry in _selection.entries) {
      final role = widget.roles.firstWhere((r) => r.id == entry.key,
          orElse: () => widget.citizens.first);
      for (var i = 0; i < entry.value; i++) {
        deck.add(role);
      }
    }
    // پر کردن با شهروند
    while (deck.length < _playerCount) {
      deck.add(widget.citizens.first);
    }
    return deck;
  }

  @override
  Widget build(BuildContext context) {
    final cards = _buildDeck();
    final mafiaSelected = _selection.keys
        .toList()
        .any((id) => widget.roles.any(
            (r) => r.id == id && r.isMafia));

    return GameShell(
      title: 'بازی سفارشی',
      subtitle: 'نقش‌های دلخواه خودت را بساز',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          DarkCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'تعداد نفرات',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ظرفیت باقی‌مانده: $_remainingSlots نفر',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.faintText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    NumberStepper(
                      value: _playerCount,
                      min: 4,
                      max: 15,
                      onChanged: (v) => setState(() => _playerCount = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _roleGroupHeader(
            emoji: '🕶️',
            title: 'نقش‌های مافیا',
            color: AppColors.red,
          ),
          ...widget.mafias.map((r) => _roleTile(r)),
          const SizedBox(height: 10),
          _roleGroupHeader(
            emoji: '🤝',
            title: 'نقش‌های شهروند',
            color: AppColors.green,
          ),
          ...widget.citizens.map((r) => _roleTile(r)),
          const SizedBox(height: 18),
          if (!mafiaSelected)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'حداقل یک نقش مافیا انتخاب کنید تا تعادل بازی حفظ شود.',
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.orange, fontSize: 12),
              ),
            ),
          GlowButton(
            label:
                'شروع بازی با ${cards.length} نفر (شهروند ${cards.where((r) => !r.isMafia).length} · مافیا ${cards.where((r) => r.isMafia).length})',
            icon: Icons.deck_rounded,
            onPressed: mafiaSelected ? () => _startDeal(cards) : null,
          ),
          const SizedBox(height: 10),
          const Text(
            'اگر نقش‌های انتخاب‌شده کمتر از نفرات باشد، بقیه با «شهروند» پر می‌شوند.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.faintText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _startDeal(List<MafiaRole> cards) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MafiaDealScreen(
          deck: cards,
          scenarioName: 'بازی سفارشی',
          scenarioEmoji: '🎲',
          color: AppColors.purple,
        ),
      ),
    );
  }

  Widget _roleGroupHeader({
    required String emoji,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTile(MafiaRole role) {
    final count = _selection[role.id] ?? 0;
    return InkWell(
      onTap: () => _toggleRole(role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: count > 0
              ? (role.isMafia ? AppColors.red : AppColors.green)
                  .withValues(alpha: 0.14)
              : AppColors.card,
          border: Border.all(
            color: count > 0
                ? (role.isMafia ? AppColors.red : AppColors.green)
                    .withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(role.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    role.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.faintText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showRoleHelp(role),
              icon: const Icon(Icons.help_outline_rounded,
                  color: AppColors.faintText, size: 20),
            ),
            if (count > 0)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (role.isMafia ? AppColors.red : AppColors.green),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white70, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  void _showRoleHelp(MafiaRole role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (role.isMafia ? AppColors.red : AppColors.green)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(role.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          role.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${role.groupEmoji} گروه ${role.group}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: role.isMafia
                                ? AppColors.red
                                : AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                role.help,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}