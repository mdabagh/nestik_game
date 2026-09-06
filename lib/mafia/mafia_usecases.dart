import 'dart:math';

import 'package:flutter/material.dart';

import '../../shared.dart';
import 'mafia_models.dart';

// ============================================================
// Mafia Card Dealer — Use Cases (منطق خالص، بدون امکانات بازی)
// ============================================================

/// سناریوهایی که برای `playerCount` مشخص Composition معتبر دارند.
class FilterScenariosByPlayerCount {
  static List<MafiaScenario> call(
    List<MafiaScenario> scenarios,
    int? playerCount,
  ) {
    if (playerCount == null) return List.of(scenarios);
    return scenarios.where((s) => s.hasCompositionFor(playerCount)).toList();
  }
}

/// جستجو روی nameFa / aliases
class SearchScenarios {
  static List<MafiaScenario> call(List<MafiaScenario> scenarios, String query) {
    final q = query.trim();
    if (q.isEmpty) return List.of(scenarios);
    return scenarios.where((s) => s.matchesQuery(q)).toList();
  }
}

/// ساخت Deck از روی Composition: هر RoleCount به چند کارتِ تکی
/// (Duplicate) تبدیل می‌شود.
class BuildDeck {
  static List<DistributionCard> toShuffledDeck(
    List<MafiaRoleCount> counts,
    Random? random,
  ) {
    final roleIds = <String>[];
    for (final rc in counts) {
      for (var i = 0; i < rc.count; i++) {
        roleIds.add(rc.roleId);
      }
    }
    final shuffledIds = shuffled(roleIds);
    return [
      for (var i = 0; i < shuffledIds.length; i++)
        DistributionCard(
          id: 'card-$i',
          position: i,
          roleId: shuffledIds[i],
          state: CardState.available,
        ),
    ];
  }
}

/// وضعیت کارت: فقط AVAILABLE → REVEALED → COMPLETED
class RevealCard {
  static List<DistributionCard> call(List<DistributionCard> cards, String id) {
    return cards.map((c) {
      if (c.id != id || c.state != CardState.available) return c;
      return c.copyWith(state: CardState.revealed);
    }).toList();
  }
}

class CompleteCard {
  static List<DistributionCard> call(List<DistributionCard> cards, String id) {
    return cards.map((c) {
      if (c.id != id || c.state != CardState.revealed) return c;
      return c.copyWith(state: CardState.completed);
    }).toList();
  }
}

class ShuffleDeck {
  static List<DistributionCard> call(
    List<DistributionCard> cards,
    Random? random,
  ) {
    final shuffled = List<DistributionCard>.of(cards);
    shuffled.shuffle(random);
    final renumbered = <DistributionCard>[];
    for (var i = 0; i < shuffled.length; i++) {
      renumbered.add(
        DistributionCard(
          id: shuffled[i].id,
          position: i,
          roleId: shuffled[i].roleId,
          state: shuffled[i].state,
        ),
      );
    }
    return renumbered;
  }
}

/// نشان‌دادن نمایشی کارت‌های پشت‌ورو — همه‌ی کارت‌ها از نظر ظاهری یکسان‌اند.
class UniformCardDesign {
  static const BorderRadius backRadius = BorderRadius.all(Radius.circular(18));
  static const BorderRadius frontRadius = BorderRadius.all(Radius.circular(26));

  static BoxDecoration backDecoration() {
    return BoxDecoration(
      borderRadius: backRadius,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6C5CE7), Color(0xFF5A4BD1)],
      ),
      border: Border.fromBorderSide(
        const BorderSide(color: Color(0x33FFFFFF)),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A6C5CE7),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration frontDecoration() {
    return BoxDecoration(
      borderRadius: frontRadius,
      color: const Color(0xFFFFFFFF),
      border: Border.fromBorderSide(
        BorderSide(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

/// گروه‌بندی نقش‌ها بر اساس فکشن برای نمایش در Details و Custom
class GroupRolesByFaction {
  static Map<Faction, List<MafiaRole>> call(List<MafiaRole> roles) {
    final map = <Faction, List<MafiaRole>>{
      Faction.mafia: [],
      Faction.citizen: [],
      Faction.independent: [],
      Faction.undecided: [],
    };
    for (final r in roles) {
      map[r.faction]!.add(r);
    }
    final ordered = <Faction, List<MafiaRole>>{
      Faction.mafia: map[Faction.mafia]!,
      Faction.citizen: map[Faction.citizen]!,
      Faction.independent: map[Faction.independent]!,
      Faction.undecided: map[Faction.undecided]!,
    };
    return ordered;
  }
}

/// عنوان/ایموجی استاندارد هر فکشن در UI
String factionLabel(Faction f) => f.labelFa;
String factionEmoji(Faction f) => f.emoji;

Color factionColor(Faction f) {
  switch (f) {
    case Faction.mafia:
      return AppColors.red;
    case Faction.citizen:
      return AppColors.green;
    case Faction.independent:
      return AppColors.orange;
    case Faction.undecided:
      return AppColors.accent;
  }
}
