import 'dart:math';

import 'package:flutter/material.dart';

import '../../shared.dart';
import '../data/mafia_repository.dart';
import '../mafia_models.dart';
import '../mafia_usecases.dart';
import 'mafia_distribution_screen.dart';
import 'mafia_widgets.dart';

// ============================================================
// پیش‌نمایش سناریو — قبل از Shuffle و توزیع
// Deck هنوز شافل نشده؛ فقط Composition انتخاب‌شده نمایش داده می‌شود.
// ============================================================

class MafiaPreviewScreen extends StatefulWidget {
  final MafiaRepository repository;
  final String title;
  final String emoji;
  final int playerCount;
  final List<MafiaRoleCount> counts;

  const MafiaPreviewScreen({
    super.key,
    required this.repository,
    required this.title,
    required this.emoji,
    required this.playerCount,
    required this.counts,
  });

  @override
  State<MafiaPreviewScreen> createState() => _MafiaPreviewScreenState();
}

class _MafiaPreviewScreenState extends State<MafiaPreviewScreen> {
  final Map<String, MafiaRole> _roles = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final roles = await widget.repository.getRoles();
      if (!mounted) return;
      setState(() {
        for (final r in roles) {
          _roles[r.id] = r;
        }
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  Map<String, int> _aggregate() {
    final map = <String, int>{};
    for (final rc in widget.counts) {
      map[rc.roleId] = (map[rc.roleId] ?? 0) + rc.count;
    }
    return map;
  }

  void _startDistribution() {
    final session = DistributionSession(
      scenarioId: 'custom',
      scenarioTitle: widget.title,
      scenarioEmoji: widget.emoji,
      playerCount: widget.playerCount,
      cards: BuildDeck.toShuffledDeck(widget.counts, Random()),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MafiaDistributionScreen(
          repository: widget.repository,
          session: session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'پیش‌نمایش سناریو',
      subtitle: '${widget.title} · ${widget.playerCount} نفر',
      child: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final aggregated = _aggregate();
    final ordered = GroupRolesByFaction.call(_roles.values.toList());
    final sections = <Widget>[];

    for (final entry in ordered.entries) {
      final roles = entry.value
          .where((r) => aggregated.containsKey(r.id))
          .toList();
      if (roles.isEmpty) continue;
      sections.add(_factionHeader(entry.key));
      sections.add(
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: roles.length,
          itemBuilder: (context, i) {
            final r = roles[i];
            return RoleGridCard(
              emoji: r.emoji,
              title: r.nameFa,
              badgeLabel: factionLabel(r.faction),
              badgeColor: factionColor(r.faction),
              countBadge: true,
              countLabel: '${aggregated[r.id]}',
              onTap: () => showRoleSheet(context, r),
            );
          },
        ),
      );
      sections.add(const SizedBox(height: 8));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.playerCount} نفر · ${widget.counts.length} نوع نقش',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'این فقط پیش‌نمایش آرایش کارت‌هاست؛ هنوز Deck شافل نشده و نقش هیچ بازیکنی ذخیره نمی‌شود.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...sections,
        const SizedBox(height: 10),
        AnimatedTapScale(
          onTap: _startDistribution,
          child: const GlowButton(
            label: 'شروع توزیع کارت‌ها 🃏',
            icon: Icons.style_rounded,
          ),
        ),
      ],
    );
  }

  Widget _factionHeader(Faction faction) {
    final accent = factionColor(faction);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
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
}