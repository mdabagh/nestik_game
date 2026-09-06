import 'package:flutter/material.dart';

import '../../shared.dart';
import '../data/mafia_repository.dart';
import '../mafia_models.dart';
import '../mafia_usecases.dart';
import 'mafia_custom_screen.dart';
import 'mafia_scenario_details_screen.dart';

// ============================================================
// صفحه‌ی اصلی Mafia Card Dealer — انتخاب سناریو (Grid 3 ستونه)
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
              child: CircularProgressIndicator(color: AppTheme.primary),
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
              color: AppTheme.mafiaRed,
              size: 46,
            ),
            const SizedBox(height: 14),
            const Text(
              'بارگذاری سناریوهای مافیا ناموفق بود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: 'تلاش دوباره',
              icon: Icons.refresh_rounded,
              filled: false,
              color: AppTheme.primary,
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
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: AppTheme.chipDecoration(selected),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
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
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppTheme.surfaceVariant,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondary,
          ),
          hintText: 'جستجوی سناریو (کاپو، Capo، ...)',
          hintStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
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
      ),
    );
  }

  Widget _buildScenarioCard(MafiaScenario scenario) {
    final accent = scenario.accentColor;
    return RoleGridCard(
      emoji: scenario.nameFa.characters.first,
      title: scenario.nameFa,
      badgeLabel: scenario.playerCountLabel(),
      badgeColor: accent,
      onTap: () => _openScenario(scenario),
    );
  }

  Widget _buildCustomCard() {
    return RoleGridCard(
      emoji: '🎲',
      title: 'بازی سفارشی',
      badgeLabel: 'خودت بساز',
      badgeColor: AppTheme.primary,
      onTap: _openCustom,
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