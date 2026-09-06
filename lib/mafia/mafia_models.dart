import 'package:flutter/material.dart';

// ============================================================
// Mafia Card Dealer — Domain Models
// ============================================================

/// فکشن‌های مجاز نقش‌ها
enum Faction {
  citizen,
  mafia,
  independent,
  undecided;

  static Faction? tryParse(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'CITIZEN':
        return Faction.citizen;
      case 'MAFIA':
        return Faction.mafia;
      case 'INDEPENDENT':
        return Faction.independent;
      case 'UNDECIDED':
        return Faction.undecided;
      default:
        return null;
    }
  }

  String get labelFa {
    switch (this) {
      case Faction.citizen:
        return 'شهروند';
      case Faction.mafia:
        return 'مافیا';
      case Faction.independent:
        return 'مستقل';
      case Faction.undecided:
        return 'بلاتکلیف';
    }
  }

  String get emoji {
    switch (this) {
      case Faction.citizen:
        return '🤝';
      case Faction.mafia:
        return '🕶️';
      case Faction.independent:
        return '🎲';
      case Faction.undecided:
        return '❓';
    }
  }
}

/// وضعیت کارت در جریان توزیع
enum CardState { available, revealed, completed }

/// نقش مافیا — یک شیء یکتا در Role Library
class MafiaRole {
  final String id;
  final String nameFa;
  final List<String> aliases;
  final Faction faction;
  final String shortDescription;
  final String detailedDescription;
  final String dutyDescription;
  final String image;
  final String emoji;

  const MafiaRole({
    required this.id,
    required this.nameFa,
    required this.aliases,
    required this.faction,
    required this.shortDescription,
    required this.detailedDescription,
    required this.dutyDescription,
    required this.image,
    this.emoji = '🧑',
  });

  factory MafiaRole.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final faction = Faction.tryParse(json['faction'] as String?);
    if (faction == null) {
      throw MafiaDataException('faction نامعتبر برای نقش $id');
    }
    return MafiaRole(
      id: id,
      nameFa: json['nameFa'] as String,
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
      faction: faction,
      shortDescription: json['shortDescription'] as String? ?? '',
      detailedDescription: json['detailedDescription'] as String? ?? '',
      dutyDescription: json['dutyDescription'] as String? ?? '',
      image: json['image'] as String? ?? 'mafia/roles/citizen.webp',
      emoji: json['emoji'] as String? ?? '🧑',
    );
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (nameFa.toLowerCase().contains(q)) return true;
    for (final a in aliases) {
      if (a.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// یک ردیف از Composition سناریو
class MafiaRoleCount {
  final String roleId;
  final int count;

  const MafiaRoleCount({required this.roleId, required this.count});

  factory MafiaRoleCount.fromJson(Map<String, dynamic> json) {
    return MafiaRoleCount(
      roleId: json['roleId'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}

/// Composition برای یک Player Count خاص
class MafiaComposition {
  final int playerCount;
  final List<MafiaRoleCount> roles;

  const MafiaComposition({required this.playerCount, required this.roles});

  factory MafiaComposition.fromJson(Map<String, dynamic> json) {
    return MafiaComposition(
      playerCount: (json['playerCount'] as num).toInt(),
      roles: (json['roles'] as List)
          .map((e) => MafiaRoleCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalCards => roles.fold(0, (sum, r) => sum + r.count);
}

/// یک سناریوی مافیا — ترکیب‌ها بر مبنای Player Count تعریف می‌شوند
class MafiaScenario {
  final String id;
  final String nameFa;
  final List<String> aliases;
  final String description;
  final List<MafiaComposition> compositions;

  const MafiaScenario({
    required this.id,
    required this.nameFa,
    required this.aliases,
    required this.description,
    required this.compositions,
  });

  factory MafiaScenario.fromJson(Map<String, dynamic> json) {
    return MafiaScenario(
      id: json['id'] as String,
      nameFa: json['nameFa'] as String,
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
      description: json['description'] as String? ?? '',
      compositions: (json['compositions'] as List)
          .map((e) => MafiaComposition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// تعدادهایی که برای این سناریو Composition معتبر دارند (مرتب‌شده)
  List<int> get availablePlayerCounts =>
      compositions.map((c) => c.playerCount).toList()..sort();

  int get minPlayerCount => compositions.fold(
    1 << 30,
    (a, c) => c.playerCount < a ? c.playerCount : a,
  );

  int get maxPlayerCount =>
      compositions.fold(-1, (a, c) => c.playerCount > a ? c.playerCount : a);

  bool hasCompositionFor(int playerCount) =>
      compositions.any((c) => c.playerCount == playerCount);

  MafiaComposition? compositionFor(int playerCount) {
    for (final c in compositions) {
      if (c.playerCount == playerCount) return c;
    }
    return null;
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (nameFa.toLowerCase().contains(q)) return true;
    for (final a in aliases) {
      if (a.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  /// متن محدوده‌ی نفرات برای نمایش روی کارت سناریو.
  /// اگر تعدادها یک بازه‌ی بدون Gap باشند «a تا b نفر»
  /// وگرنه «مناسب برای: … نفر» نمایش داده می‌شود.
  String playerCountLabel() {
    final counts = availablePlayerCounts;
    if (counts.isEmpty) return '';
    final contiguous = counts.last - counts.first + 1 == counts.length;
    final listFa = counts.map((c) => '$c').join('، ');
    if (contiguous && counts.first == counts.last) {
      return '${counts.first} نفر';
    }
    if (contiguous) {
      return '${counts.first} تا ${counts.last} نفر';
    }
    return 'مناسب برای: $listFa نفر';
  }

  Color get accentColor {
    const palette = [
      Color(0xFF6C4DFF),
      Color(0xFFE84D8A),
      Color(0xFFE58B32),
      Color(0xFF39BFA7),
      Color(0xFF4D9DFF),
      Color(0xFFB44DFF),
      Color(0xFFFF8A3D),
    ];
    return palette[id.hashCode.abs() % palette.length];
  }
}

/// مدل ریشه‌ی فایل JSON
class MafiaData {
  final int version;
  final List<MafiaScenario> scenarios;
  final List<MafiaRole> roles;

  const MafiaData({
    required this.version,
    required this.scenarios,
    required this.roles,
  });

  factory MafiaData.fromJson(Map<String, dynamic> json) {
    return MafiaData(
      version: (json['version'] as num?)?.toInt() ?? 1,
      scenarios: (json['scenarios'] as List)
          .map((e) => MafiaScenario.fromJson(e as Map<String, dynamic>))
          .toList(),
      roles: (json['roles'] as List)
          .map((e) => MafiaRole.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// خطای اعتبارسنجی داده‌های JSON
class MafiaDataException implements Exception {
  final String message;
  const MafiaDataException(this.message);

  @override
  String toString() => 'MafiaDataException: $message';
}

// ============================================================
// Runtime Session (فقط در Memory)
// ============================================================

/// کارت در حال توزیع — شماره فقط نمایشی است و به هیچ Player متصل نیست
class DistributionCard {
  final String id;
  final int position;
  final String roleId;
  final CardState state;

  const DistributionCard({
    required this.id,
    required this.position,
    required this.roleId,
    required this.state,
  });

  DistributionCard copyWith({CardState? state}) {
    return DistributionCard(
      id: id,
      position: position,
      roleId: roleId,
      state: state ?? this.state,
    );
  }

  String get displayNumber => (position + 1).toString().padLeft(2, '0');
}

/// نشست توزیع — فقط در حافظه و پس از خروج پاک می‌شود
class DistributionSession {
  final String? scenarioId;
  final String scenarioTitle;
  final String scenarioEmoji;
  final int playerCount;
  final List<DistributionCard> cards;

  const DistributionSession({
    required this.scenarioId,
    required this.scenarioTitle,
    required this.scenarioEmoji,
    required this.playerCount,
    required this.cards,
  });

  int get remaining =>
      cards.where((c) => c.state != CardState.completed).length;

  bool get allCompleted => cards.every((c) => c.state == CardState.completed);
}
