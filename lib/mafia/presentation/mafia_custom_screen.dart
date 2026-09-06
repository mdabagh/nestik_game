import 'package:flutter/material.dart';

import '../../shared.dart';
import '../data/mafia_repository.dart';
import '../mafia_models.dart';
import '../mafia_usecases.dart';
import 'mafia_preview_screen.dart';
import 'mafia_widgets.dart';

// ============================================================
// سناریوی سفارشی — Runtime only
// Flow: انتخاب تعداد نفرات ← انتخاب نقش از کل Role Library
//       ← ادامه ← Preview ← شروع توزیع
// ============================================================

enum _CustomPhase { count, picker }

class MafiaCustomScreen extends StatefulWidget {
  final MafiaRepository repository;

  const MafiaCustomScreen({super.key, required this.repository});

  @override
  State<MafiaCustomScreen> createState() => _MafiaCustomScreenState();
}

class _MafiaCustomScreenState extends State<MafiaCustomScreen> {
  List<MafiaRole> _roles = [];
  bool _loaded = false;

  _CustomPhase _phase = _CustomPhase.count;
  int _playerCount = 8;
  final Map<String, int> _selected = {};
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<int> _suggestedCounts = [8, 9, 10, 11, 12, 13, 14, 15];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final roles = await widget.repository.getRoles();
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  int get _totalCards => _selected.values.fold(0, (a, b) => a + b);
  bool get _valid => _totalCards == _playerCount && _playerCount > 3;

  List<MafiaRole> get _visibleRoles {
    final q = _query.trim();
    if (q.isEmpty) return _roles;
    return _roles.where((r) => r.matchesQuery(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'سناریوی سفارشی',
      subtitle: _phase == _CustomPhase.count
          ? 'تعداد نفرات را انتخاب کنید'
          : 'کارت‌ها را از کل Role Library انتخاب کن',
      child: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _phase == _CustomPhase.count
          ? _buildCountStep()
          : _buildPickerStep(),
    );
  }

  // ---------- مرحله ۱: انتخاب تعداد نفرات ----------

  Widget _buildCountStep() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'برای چند بازیکن باید کارت توزیع شود؟',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              for (final c in _suggestedCounts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedTapScale(
                    onTap: () {
                      setState(() {
                        _playerCount = c;
                        _phase = _CustomPhase.picker;
                        _selected.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(color: AppTheme.cardBorder),
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
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: Text(
                              '$c',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$c نفر',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- مرحله ۲: انتخاب کارت‌ها ----------

  Widget _buildPickerStep() {
    final ordered = GroupRolesByFaction.call(_visibleRoles);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              _buildSearch(),
              const SizedBox(height: 10),
              _summaryCard(),
              const SizedBox(height: 12),
              for (final entry in ordered.entries)
                if (entry.value.isNotEmpty) ...[
                  _factionHeader(entry.key),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, i) {
                      final r = entry.value[i];
                      final count = _selected[r.id] ?? 0;
                      final accent = factionColor(r.faction);
                      return RoleGridCard(
                        emoji: r.emoji,
                        title: r.nameFa,
                        badgeLabel: factionLabel(r.faction),
                        badgeColor: accent,
                        countBadge: count > 0,
                        countLabel: '$count',
                        onTap: () => showRoleSheet(context, r),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.textSecondary,
        ),
        hintText: 'جستجو… (پدرخوانده، Godfather، ...)',
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
      onChanged: (v) => setState(() => _query = v),
    );
  }

  Widget _summaryCard() {
    return DarkCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'تعداد بازیکنان: $_playerCount',
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
          Text(
            'کارت‌های انتخاب‌شده: $_totalCards / $_playerCount',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _valid ? AppTheme.success : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factionHeader(Faction faction) {
    final accent = factionColor(faction);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Text(factionEmoji(faction), style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 8),
          Text(
            factionLabel(faction),
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final missing = _playerCount - _totalCards;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: _valid
          ? GlowButton(
              label: 'ادامه',
              icon: Icons.arrow_forward_rounded,
              onPressed: _goToPreview,
            )
          : GlowButton(
              label: missing > 0
                  ? 'هنوز $missing کارت دیگر انتخاب کنید'
                  : 'فراتر از تعداد، کارتی نمی‌توان افزود',
              icon: Icons.lock_outline_rounded,
              filled: false,
              color: AppTheme.textSecondary,
              onPressed: null,
            ),
    );
  }

  void _goToPreview() {
    if (!_valid) return;
    final counts = <MafiaRoleCount>[
      for (final e in _selected.entries)
        if (e.value > 0) MafiaRoleCount(roleId: e.key, count: e.value),
    ];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MafiaPreviewScreen(
          repository: widget.repository,
          title: 'سناریوی سفارشی',
          emoji: '🎲',
          playerCount: _playerCount,
          counts: counts,
        ),
      ),
    );
  }
}