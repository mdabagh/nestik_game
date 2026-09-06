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
              child: CircularProgressIndicator(color: AppColors.purple),
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
                    color: AppColors.mutedText,
                    fontSize: 14,
                  ),
                ),
              ),
              for (final c in _suggestedCounts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
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
                          borderRadius: BorderRadius.circular(20),
                          color: c == _playerCount
                              ? AppColors.purple.withValues(alpha: 0.22)
                              : AppColors.card,
                          border: Border.all(
                            color: c == _playerCount
                                ? AppColors.purple
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$c',
                                style: const TextStyle(
                                  color: Colors.white,
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
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.faintText,
                            ),
                          ],
                        ),
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
                  ...entry.value.map((r) => _rolePickerTile(r)),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF191631),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.faintText,
        ),
        hintText: 'جستجو… (پدرخوانده، Godfather، ...)',
        hintStyle: const TextStyle(color: AppColors.faintText, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purple),
        ),
      ),
      onChanged: (v) => setState(() => _query = v),
    );
  }

  Widget _summaryCard() {
    return DarkCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'تعداد بازیکنان: $_playerCount',
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            'کارت‌های انتخاب‌شده: $_totalCards / $_playerCount',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _valid ? AppColors.green : AppColors.mutedText,
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
        textDirection: TextDirection.rtl,
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

  Widget _rolePickerTile(MafiaRole role) {
    final count = _selected[role.id] ?? 0;
    final accent = factionColor(role.faction);
    final addDisabled = _totalCards >= _playerCount;
    return DarkCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showRoleSheet(context, role),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(role.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      role.nameFa,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      role.shortDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.faintText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (count == 0)
                InkWell(
                  onTap: () => addDisabled ? null : _add(role.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: addDisabled ? AppColors.faintText : accent,
                      size: 22,
                    ),
                  ),
                )
              else
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    _stepperIcon(
                      Icons.remove_rounded,
                      () => _remove(role.id),
                      accent,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _stepperIcon(
                      Icons.add_rounded,
                      addDisabled ? null : () => _add(role.id),
                      accent,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperIcon(IconData icon, VoidCallback? onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _add(String id) {
    if (_totalCards >= _playerCount) return;
    setState(() => _selected[id] = (_selected[id] ?? 0) + 1);
  }

  void _remove(String id) {
    setState(() {
      final c = _selected[id] ?? 0;
      if (c <= 1) {
        _selected.remove(id);
      } else {
        _selected[id] = c - 1;
      }
    });
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
              color: AppColors.faintText,
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
