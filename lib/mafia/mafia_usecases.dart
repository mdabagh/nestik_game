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
  static BoxDecoration backDecoration() {
    return const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2B2260), Color(0xFF171233)],
      ),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFF4A4278))),
    );
  }

  static BoxDecoration frontDecoration() {
    return const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(26)),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF29205D), Color(0xFF19143B)],
      ),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFF4A4278))),
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
