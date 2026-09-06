import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../mafia_models.dart';

// ============================================================
// Mafia JSON Data Source — تنها Source of Truth داده‌ی مافیا
// ============================================================

class MafiaJsonDataSource {
  static const String assetPath = 'assets/data/mafia_data.json';

  const MafiaJsonDataSource();

  /// فایل JSON را می‌خواند، پارس می‌کند و اعتبارسنجی می‌کند.
  Future<MafiaData> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const MafiaDataException('ساختار ریشه‌ی JSON معتبر نیست.');
    }
    final data = MafiaData.fromJson(decoded);
    validate(data);
    return data;
  }

  /// بند ۳۵ (پچ) — Validation:
  /// Role: id خالی/تکراری نباشد، nameFa موجود، faction معتبر
  /// Scenario: ارجاع نقش‌ها معتبر، Composition معتبر
  /// Composition: sum(role.count) == playerCount
  void validate(MafiaData data) {
    final roleIds = <String>{};
    for (final role in data.roles) {
      if (role.id.trim().isEmpty) {
        throw const MafiaDataException('Role با id خالی پیدا شد.');
      }
      if (roleIds.contains(role.id)) {
        throw MafiaDataException('id تکراری برای نقش: ${role.id}');
      }
      if (role.nameFa.trim().isEmpty) {
        throw MafiaDataException('نقش ${role.id} باید nameFa داشته باشد.');
      }
      if (role.shortDescription.isEmpty || role.dutyDescription.isEmpty) {
        throw MafiaDataException('توضیحات نقش ${role.id} ناقص است.');
      }
      roleIds.add(role.id);
    }

    for (final scenario in data.scenarios) {
      if (scenario.id.trim().isEmpty) {
        throw const MafiaDataException('سناریو با id خالی پیدا شد.');
      }
      if (scenario.compositions.isEmpty) {
        throw MafiaDataException(
          'سناریو ${scenario.id} دست‌کم یک Composition ندارد.',
        );
      }
      var last = -1;
      for (final composition in scenario.compositions) {
        if (composition.playerCount <= 0 || composition.playerCount > 30) {
          throw MafiaDataException(
            'playerCount نامعتبر در سناریو ${scenario.id}.',
          );
        }
        if (composition.playerCount < last) {
          throw MafiaDataException(
            'compositions سناریو ${scenario.id} مرتب نیستند.',
          );
        }
        last = composition.playerCount;
        if (composition.totalCards != composition.playerCount ||
            composition.roles.isEmpty) {
          throw MafiaDataException(
            'composition سناریو ${scenario.id} برای '
            '${composition.playerCount} نفر معتبر نیست '
            '(نقش‌ها: ${composition.totalCards}).',
          );
        }
        for (final rc in composition.roles) {
          if (!roleIds.contains(rc.roleId)) {
            throw MafiaDataException(
              'ارجاع نامعتبر به نقش ${rc.roleId} در سناریو ${scenario.id}.',
            );
          }
          if (rc.count <= 0) {
            throw MafiaDataException(
              'تعداد نامعتبر برای نقش ${rc.roleId} در سناریو ${scenario.id}.',
            );
          }
        }
      }
    }
  }
}
