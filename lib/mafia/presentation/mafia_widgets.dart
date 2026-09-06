import 'package:flutter/material.dart';

import '../../shared.dart';
import '../mafia_models.dart';
import '../mafia_usecases.dart';

// ============================================================
// ویجت‌های مشترک Mafia Card Dealer
// ============================================================

Future<void> showRoleSheet(BuildContext context, MafiaRole role) {
  final accent = factionColor(role.faction);
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        role.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            role.nameFa,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  role.aliases.isEmpty
                                      ? role.shortDescription
                                      : role.aliases.join(' · '),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${factionEmoji(role.faction)} ${factionLabel(role.faction)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sheetSection(
                  'توضیح کوتاه',
                  role.shortDescription,
                  accent,
                ),
                const SizedBox(height: 12),
                _sheetSection(
                  'توضیح کامل',
                  role.detailedDescription,
                  AppTheme.primary,
                ),
                const SizedBox(height: 12),
                _sheetSection('وظیفه در بازی', role.dutyDescription, accent),
                const SizedBox(height: 20),
                GlowButton(
                  label: 'بستن',
                  icon: Icons.close_rounded,
                  filled: false,
                  color: accent,
                  height: 48,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _sheetSection(String title, String body, Color color) {
  return DarkCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body.trim().isEmpty ? '—' : body,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.7,
          ),
        ),
      ],
    ),
  );
}

/// یک آیتم نمایشی Count نقش در صفحه‌ی جزئیات سناریو
class RoleCountTile extends StatelessWidget {
  final MafiaRole role;
  final int count;
  final VoidCallback? onTap;

  const RoleCountTile({
    super.key,
    required this.role,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = factionColor(role.faction);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Text(role.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    role.nameFa,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.aliases.join(' · '),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '× $count',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.help_outline_rounded,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}