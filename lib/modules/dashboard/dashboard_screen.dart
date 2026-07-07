import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/standing_model.dart';
import 'dashboard_controller.dart';

// =============================================================================
// League Options — shown in the horizontal selector
// =============================================================================

class _LeagueOption {
  final String code;
  final String name;
  final String flag;
  const _LeagueOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}

const _leagues = [
  _LeagueOption(code: 'PL', name: 'Premier League', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
  _LeagueOption(code: 'PD', name: 'La Liga', flag: '🇪🇸'),
  _LeagueOption(code: 'BL1', name: 'Bundesliga', flag: '🇩🇪'),
  _LeagueOption(code: 'SA', name: 'Serie A', flag: '🇮🇹'),
  _LeagueOption(code: 'FL1', name: 'Ligue 1', flag: '🇫🇷'),
];

// =============================================================================
// DashboardScreen
// =============================================================================

class DashboardScreen extends GetView<FootballController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header + League Selector are always visible
            _buildHeader(),
            _buildLeagueSelector(),
            // Body reacts to state
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && !controller.hasData) {
                  return _buildShimmerLoading();
                }
                if (controller.hasError && !controller.hasData) {
                  return _buildErrorState();
                }
                // Loaded successfully but standings still empty →
                // competition not in free-tier or genuinely no data
                if (!controller.isLoading.value && !controller.hasData) {
                  return _buildEmptyState();
                }
                return _buildContent(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
      ),
      child: Row(
        children: [
          Obx(() => _CompetitionEmblem(url: controller.competitionEmblem)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    controller.competitionName,
                    style: GoogleFonts.rajdhani(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Obx(
                  () => Text(
                    controller.seasonLabel.isNotEmpty
                        ? 'Matchday ${controller.currentMatchday}  ·  ${controller.seasonLabel}'
                        : 'Matchday ${controller.currentMatchday}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _LiveBadge(),
        ],
      ),
    );
  }

  // ── League Selector ─────────────────────────────────────────────────────────

  Widget _buildLeagueSelector() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          itemCount: _leagues.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final league = _leagues[index];
            return Obx(() {
              final isSelected =
                  controller.selectedLeague.value == league.code;
              return GestureDetector(
                onTap: () => controller.changeLeague(league.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent.withOpacity(0.12)
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accent
                          : AppTheme.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        league.flag,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        league.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  // ── Scrollable Content ──────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.fetchStandings,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceElevated,
      strokeWidth: 2.5,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            const _SectionLabel(text: 'SEASON AT A GLANCE'),
            const SizedBox(height: 12),
            _buildStatsGrid(),
            const SizedBox(height: 26),
            const _SectionLabel(text: 'LEAGUE TABLE'),
            const SizedBox(height: 12),
            _buildStandingsTable(),
            const SizedBox(height: 18),
            _buildZoneLegend(),
          ],
        ),
      ),
    );
  }

  // ── Stats Grid ──────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: [
          Obx(() => _StatCard(
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.accentGold,
                label: 'LEAGUE LEADER',
                value: controller.leagueLeader?.team.shortName ?? '—',
                subValue: '${controller.leagueLeader?.points ?? 0} pts',
                borderColor: AppTheme.accentGold,
              )),
          Obx(() => _StatCard(
                icon: Icons.sports_soccer_rounded,
                iconColor: AppTheme.accentGreen,
                label: 'TOTAL GOALS',
                value: '${controller.totalGoalsScored}',
                subValue: 'scored this season',
                borderColor: AppTheme.accentGreen,
              )),
          Obx(() => _StatCard(
                icon: Icons.calendar_month_rounded,
                iconColor: AppTheme.accent,
                label: 'MATCHDAY',
                value: '${controller.currentMatchday}',
                subValue: 'of 38 played',
                borderColor: AppTheme.accent,
              )),
          Obx(() => _StatCard(
                icon: Icons.show_chart_rounded,
                iconColor: const Color(0xFFBB86FC),
                label: 'AVG GOALS/MATCH',
                value: controller.avgGoalsPerMatch.toStringAsFixed(1),
                subValue: 'per match avg.',
                borderColor: const Color(0xFFBB86FC),
              )),
        ],
      ),
    );
  }

  // ── Standings Table ─────────────────────────────────────────────────────────

  Widget _buildStandingsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              _buildTableHeader(),
              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.standings.length,
                  itemBuilder: (_, index) {
                    return _StandingRowWidget(
                      standing: controller.standings[index],
                      totalTeams: controller.standings.length,
                      isLast: index == controller.standings.length - 1,
                      isEven: index.isEven,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: AppTheme.surfaceElevated,
      child: Row(
        children: [
          const SizedBox(width: 28), // position badge
          const SizedBox(width: 10),
          const SizedBox(width: 30), // crest
          const SizedBox(width: 10),
          const Expanded(
            flex: 5,
            child: Text(
              'CLUB',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const _HeaderCell(label: 'P'),
          const _HeaderCell(label: 'W'),
          const _HeaderCell(label: 'D'),
          const _HeaderCell(label: 'L'),
          const _HeaderCell(label: 'PTS', width: 36, isAccent: true),
        ],
      ),
    );
  }

  // ── Zone Legend ─────────────────────────────────────────────────────────────

  Widget _buildZoneLegend() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _LegendItem(color: AppTheme.accent, label: 'Champions League'),
          _LegendItem(color: Color(0xFFFF6F00), label: 'Europa League'),
          _LegendItem(color: AppTheme.accentGreen, label: 'Conference League'),
          _LegendItem(color: AppTheme.accentRed, label: 'Relegation Zone'),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.sports_soccer_rounded,
                color: AppTheme.accentGold,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Available',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This competition is not available\non your current plan, or the season\nhasn\'t started yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: controller.fetchStandings,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.divider, width: 1),
                ),
                child: Text(
                  'TRY AGAIN',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ─────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.accentRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.accentRed,
                size: 38,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Connection Failed',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Text(
                controller.errorMessage.value ??
                    'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: controller.fetchStandings,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'TRY AGAIN',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer Loading ─────────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHighlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Label
            Container(
              height: 10,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 14),
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: List.generate(
                4,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Label
            Container(
              height: 10,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 14),
            // Table header
            Container(
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            // Rows
            ...List.generate(
              12,
              (i) => Container(
                height: 56,
                margin: const EdgeInsets.only(top: 1),
                color: Colors.white,
              ),
            ),
            Container(
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Private Widget Components
// =============================================================================

class _CompetitionEmblem extends StatelessWidget {
  final String url;
  const _CompetitionEmblem({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(),
              errorWidget: (_, __, ___) => const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.accentGold,
                size: 24,
              ),
            )
          : const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.accentGold,
              size: 24,
            ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subValue;
  final Color borderColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subValue,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subValue,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fixed-width header cell. [width] defaults to 30, use 36 for PTS.
class _HeaderCell extends StatelessWidget {
  final String label;
  final bool isAccent;
  final double width;

  const _HeaderCell({
    required this.label,
    this.isAccent = false,
    this.width = 30,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isAccent ? AppTheme.accent : AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Redesigned standings row:
/// • Colored circular position badge (replaces the thin left strip)
/// • Alternating row background for readability
/// • Points in a styled badge container
class _StandingRowWidget extends StatelessWidget {
  final Standing standing;
  final int totalTeams;
  final bool isLast;
  final bool isEven;

  const _StandingRowWidget({
    required this.standing,
    required this.totalTeams,
    required this.isLast,
    required this.isEven,
  });

  Color get _zoneColor {
    final pos = standing.position;
    if (pos <= 4) return AppTheme.accent;
    if (pos <= 6) return const Color(0xFFFF6F00);
    if (pos == 7) return AppTheme.accentGreen;
    if (pos >= totalTeams - 2) return AppTheme.accentRed;
    return AppTheme.textSecondary;
  }

  bool get _isZoned {
    final pos = standing.position;
    return pos <= 7 || pos >= totalTeams - 2;
  }

  @override
  Widget build(BuildContext context) {
    final zoneColor = _zoneColor;
    final isZoned = _isZoned;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        // Subtle alternating stripe for long lists
        color: isEven
            ? Colors.transparent
            : AppTheme.surfaceElevated.withOpacity(0.4),
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppTheme.divider, width: 0.4),
        ),
      ),
      child: Row(
        children: [
          // ── Position Badge ──────────────────────────────────────────
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isZoned
                  ? zoneColor.withOpacity(0.12)
                  : AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: isZoned
                    ? zoneColor.withOpacity(0.45)
                    : AppTheme.divider,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${standing.position}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isZoned ? zoneColor : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Team Crest ──────────────────────────────────────────────
          SizedBox(
            width: 30,
            height: 30,
            child: CachedNetworkImage(
              imageUrl: standing.team.crestUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.shield_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Team Name ───────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Text(
              standing.team.shortName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // ── Played ──────────────────────────────────────────────────
          _StatCell('${standing.playedGames}'),
          // ── Won ─────────────────────────────────────────────────────
          _StatCell(
            '${standing.won}',
            color: standing.won > 0
                ? AppTheme.accentGreen
                : AppTheme.textSecondary,
          ),
          // ── Draw ────────────────────────────────────────────────────
          _StatCell(
            '${standing.draw}',
            color: standing.draw > 0
                ? AppTheme.accentDraw
                : AppTheme.textSecondary,
          ),
          // ── Lost ────────────────────────────────────────────────────
          _StatCell(
            '${standing.lost}',
            color: standing.lost > 0
                ? AppTheme.accentRed
                : AppTheme.textSecondary,
          ),
          // ── Points Badge ────────────────────────────────────────────
          Container(
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: isZoned
                  ? zoneColor.withOpacity(0.10)
                  : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isZoned
                    ? zoneColor.withOpacity(0.3)
                    : AppTheme.divider,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${standing.points}',
                style: GoogleFonts.rajdhani(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isZoned ? zoneColor : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed-width stat cell used inside [_StandingRowWidget].
class _StatCell extends StatelessWidget {
  final String value;
  final Color color;

  const _StatCell(this.value, {this.color = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
