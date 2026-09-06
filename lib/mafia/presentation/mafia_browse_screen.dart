import 'package:flutter/material.dart';

import '../../shared.dart';
import '../data/mafia_repository.dart';
import '../mafia_models.dart';
import '../mafia_usecases.dart';
import 'mafia_custom_screen.dart';
import 'mafia_scenario_details_screen.dart';

// ============================================================
// صفحه‌ی اصلی Mafia Card Dealer — انتخاب سناریو
// ============================================================

class MafiaBrowseScreen extends StatefulWidget {
  const MafiaBrowseScreen({super.key});

  @override
  State<MafiaBrowseScreen> createState() => _MafiaBrowseScreenState();
}

class _MafiaBrowseScreenState extends State<MafiaBrowseScreen> {
  final MafiaRepository _repository = MafiaJsonRepository();

  List<MafiaScenario>? _scenarios;
  Object? _error;

  int? _playerCount;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

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
    setState(() {
      _error = null;
    });
    try {
      final scenarios = await _repository.getScenarios();
      if (!mounted) return;
      setState(() => _scenarios = scenarios);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _openHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HelpPage(
          title: 'مافیا — توزیع کارت',
          icon: Icons.style_rounded,
          steps: [
            'تعداد بازیکن را انتخاب کنید یا روی «همه» بگذارید تا همه‌ی سناریوها دیده شوند.',
            'با جستجو می‌توانید سناریو را با نام فارسی، انگلیسی یا نام‌های دیگر پیدا کنید.',
            'روی یک سناریو بزنید تا نقش‌های آن را بر اساس تیم ببینید و توزیع را شروع کنید.',
            '«بازی سفارشی» را می‌توانید برای ساخت Deck دلخواه خودتان استفاده کنید.',
            'در توزیع، کارت‌ها پشت‌ورو و با رنگ یکسان نمایش داده می‌شوند؛ فقط انتخاب‌شده باز می‌شود و پس از مشاهده قفل می‌ماند.',
            'این برنامه فقط Deck را توزیع می‌کند؛ موتور شب، رأی‌گیری و برنده در آن وجود ندارد.',
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'بازی مافیا 🕶️',
      subtitle: 'توزیع محرمانه‌ی کارت‌های مافیا',
      trailing: HelpTrailing(onPressed: _openHelp),
      child: _error != null
          ? _buildError()
          : _scenarios == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.red,
              size: 46,
            ),
            const SizedBox(height: 14),
            const Text(
              'بارگذاری سناریوهای مافیا ناموفق بود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: 'تلاش دوباره',
              icon: Icons.refresh_rounded,
              filled: false,
              color: AppColors.purple,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final byCount = FilterScenariosByPlayerCount.call(_scenarios!, _playerCount);
    final filtered = SearchScenarios.call(byCount, _query);

    return Column(
      children: [
        _buildCountFilter(),
        _buildSearch(),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'سناریویی مطابق این ترکیب پیدا نشد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.faintText),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return _buildCustomCard();
                    }
                    return _buildScenarioCard(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCountFilter() {
    const counts = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        children: [
          _countChip('همه', _playerCount == null, () {
            setState(() => _playerCount = null);
          }),
          for (final c in counts.reversed)
            _countChip('$c', _playerCount == c, () {
              setState(() => _playerCount = c);
            }),
        ],
      ),
    );
  }

  Widget _countChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: selected
                ? AppColors.purple.withValues(alpha: 0.35)
                : AppColors.card,
            border: Border.all(
              color: selected
                  ? AppColors.purple
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: TextField(
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
          hintText: 'جستجوی سناریو (کاپو، Capo، ...)',
          hintStyle: const TextStyle(color: AppColors.faintText, fontSize: 13),
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
      ),
    );
  }

  Widget _buildScenarioCard(MafiaScenario scenario) {
    final accent = scenario.accentColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openScenario(scenario),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accent.withValues(alpha: 0.10),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    scenario.nameFa.characters.first,
                    style: TextStyle(
                      color: accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                              scenario.nameFa,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        scenario.playerCountLabel(),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.faintText,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openCustom(),
        child: Container(
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
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 26,
                ),
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
                      'خودت تعداد نفرات و نقش‌ها را انتخاب کن',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
    );
  }

  void _openScenario(MafiaScenario scenario) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MafiaScenarioDetailsScreen(
          repository: _repository,
          scenario: scenario,
          initialPlayerCount: scenario.hasCompositionFor(_playerCount ?? -1)
              ? _playerCount
              : null,
        ),
      ),
    );
  }

  void _openCustom() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MafiaCustomScreen(repository: _repository),
      ),
    );
  }
}
