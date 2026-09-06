import 'package:flutter/material.dart';

import '../../shared.dart';
import '../data/mafia_repository.dart';
import '../mafia_models.dart';
import '../mafia_usecases.dart';
import 'mafia_distribution_screen.dart';
import 'mafia_widgets.dart';

// ============================================================
// صفحه‌ی جزئیات سناریو — ترکیب نقش‌ها بر اساس فکشن
// ============================================================

class MafiaScenarioDetailsScreen extends StatefulWidget {
  final MafiaRepository repository;
  final MafiaScenario scenario;
  final int? initialPlayerCount;

  const MafiaScenarioDetailsScreen({
    super.key,
    required this.repository,
    required this.scenario,
    this.initialPlayerCount,
  });

  @override
  State<MafiaScenarioDetailsScreen> createState() =>
      _MafiaScenarioDetailsScreenState();
}

class _MafiaScenarioDetailsScreenState
    extends State<MafiaScenarioDetailsScreen> {
  late int _playerCount;
  Map<String, MafiaRole> _roles = {};
  bool _rolesLoaded = false;

  @override
  void initState() {
    super.initState();
    final counts = widget.scenario.availablePlayerCounts;
    final initial = widget.initialPlayerCount;
    _playerCount =
        (initial != null && widget.scenario.hasCompositionFor(initial))
        ? initial
        : (counts.isNotEmpty ? counts.first : 8);
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await widget.repository.getRoles();
      if (!mounted) return;
      setState(() {
        final map = <String, MafiaRole>{};
        for (final r in roles) {
          map[r.id] = r;
        }
        _roles = map;
        _rolesLoaded = true;
      });
    } catch (_) {
      // بدون نقش‌ها هم می‌توان ترکیب را نمایش داد
    }
  }

  MafiaComposition? get _composition =>
      widget.scenario.compositionFor(_playerCount);

  Map<String, int> _countsFor(MafiaComposition composition) {
    final counts = <String, int>{};
    for (final rc in composition.roles) {
      counts[rc.roleId] = (counts[rc.roleId] ?? 0) + rc.count;
    }
    return counts;
  }

  void _startDistribution() {
    final composition = _composition;
    if (composition == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MafiaDistributionScreen(
          repository: widget.repository,
          session: DistributionSession(
            scenarioId: widget.scenario.id,
            scenarioTitle: widget.scenario.nameFa,
            scenarioEmoji: widget.scenario.nameFa.characters.first,
            playerCount: _playerCount,
            cards: BuildDeck.toShuffledDeck(composition.roles, null),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    final composition = _composition;
    return GameShell(
      title: scenario.nameFa,
      subtitle: '$_playerCount نفر',
      child: _rolesLoaded && composition != null
          ? _buildBody(scenario, composition)
          : const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            ),
    );
  }

  Widget _buildBody(MafiaScenario scenario, MafiaComposition composition) {
    final counts = _countsFor(composition);
    final ordered = GroupRolesByFaction.call(_roles.values.toList());

    return ListView(
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
                  const Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.accent,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تعداد بازیکن · بدون گاد',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _countChips(),
              const SizedBox(height: 8),
              Text(
                scenario.description,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // نقش‌ها بر اساس فکشن
        ..._buildFactionSections(counts, ordered),
        const SizedBox(height: 10),
        GlowButton(
          label: 'شروع توزیع کارت‌ها 🃏',
          icon: Icons.style_rounded,
          onPressed: _startDistribution,
        ),
      ],
    );
  }

  Widget _countChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in widget.scenario.availablePlayerCounts)
          InkWell(
            onTap: () => setState(() => _playerCount = c),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: c == _playerCount
                    ? AppColors.purple.withValues(alpha: 0.35)
                    : const Color(0xFF241E4D),
                border: Border.all(
                  color: c == _playerCount
                      ? AppColors.purple
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                '$c نفر',
                style: TextStyle(
                  color: c == _playerCount ? Colors.white : AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildFactionSections(
    Map<String, int> counts,
    Map<Faction, List<MafiaRole>> ordered,
  ) {
    final sections = <Widget>[];
    for (final entry in ordered.entries) {
      final entryRoles = entry.value
          .where((r) => counts.containsKey(r.id))
          .toList();
      if (entryRoles.isEmpty) continue;
      sections.add(_factionHeader(entry.key, entryRoles.length));
      for (final r in entryRoles) {
        sections.add(
          RoleCountTile(
            role: r,
            count: counts[r.id]!,
            onTap: () => showRoleSheet(context, r),
          ),
        );
      }
      sections.add(const SizedBox(height: 8));
    }
    return sections;
  }

  Widget _factionHeader(Faction faction, int distinctCount) {
    final color = factionColor(faction);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(factionEmoji(faction), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            factionLabel(faction),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$distinctCount نقش',
            style: const TextStyle(color: AppColors.faintText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
