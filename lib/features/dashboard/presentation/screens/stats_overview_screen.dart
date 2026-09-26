import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/presentation/providers/team_providers.dart';

// ─── Extended Aggregated Player Stats Model ──────────────────────────────────
class PlayerTournamentStats {
  final Player player;
  final String teamName;
  final int runs;
  final int fours;
  final int sixes;
  final int wickets;
  final int catches;
  final int stumps;
  final int matches;
  final int highestScore;
  final double average;

  const PlayerTournamentStats({
    required this.player,
    required this.teamName,
    required this.runs,
    required this.fours,
    required this.sixes,
    required this.wickets,
    required this.catches,
    required this.stumps,
    required this.matches,
    required this.highestScore,
    required this.average,
  });
}

// ─── Provider: Computes Live Ball-by-Ball & Player Stats for ALL Players ──────
final tournamentStatsProvider = FutureProvider<List<PlayerTournamentStats>>((ref) async {
  final players = await ref.watch(allPlayersProvider.future);
  final teamsAsync = ref.watch(allTeamsProvider);
  final teams = teamsAsync.value ?? [];

  final Map<String, String> teamNames = {
    for (final t in teams) t.id: t.name,
  };

  final sb = Supabase.instance.client;

  // Fetch ball-by-ball events for live boundaries, catches, stumps
  List<Map<String, dynamic>> balls = [];
  try {
    final res = await sb.from('ball_events').select(
      'batter_id, bowler_id, fielder_id, runs_scored, is_boundary, extras_type, wicket_type, player_out_id'
    );
    balls = List<Map<String, dynamic>>.from(res);
  } catch (_) {
    balls = [];
  }

  final Map<String, int> ballRuns = {};
  final Map<String, int> ballFours = {};
  final Map<String, int> ballSixes = {};
  final Map<String, int> ballWickets = {};
  final Map<String, int> ballCatches = {};
  final Map<String, int> ballStumps = {};

  for (final b in balls) {
    final batterId = b['batter_id'] as String?;
    final bowlerId = b['bowler_id'] as String?;
    final fielderId = b['fielder_id'] as String?;
    final runsScored = b['runs_scored'] as int? ?? 0;
    final wicketType = b['wicket_type'] as String?;
    final isBoundary = b['is_boundary'] as bool? ?? false;

    if (batterId != null) {
      ballRuns[batterId] = (ballRuns[batterId] ?? 0) + runsScored;
      if (isBoundary && runsScored == 4) {
        ballFours[batterId] = (ballFours[batterId] ?? 0) + 1;
      }
      if (isBoundary && runsScored == 6) {
        ballSixes[batterId] = (ballSixes[batterId] ?? 0) + 1;
      }
    }

    if (bowlerId != null && wicketType != null) {
      final bowlerWickets = ['bowled', 'lbw', 'caught', 'stumped', 'hitWicket'];
      if (bowlerWickets.contains(wicketType)) {
        ballWickets[bowlerId] = (ballWickets[bowlerId] ?? 0) + 1;
      }
    }

    if (fielderId != null) {
      if (wicketType == 'caught') {
        ballCatches[fielderId] = (ballCatches[fielderId] ?? 0) + 1;
      }
      if (wicketType == 'stumped') {
        ballStumps[fielderId] = (ballStumps[fielderId] ?? 0) + 1;
      }
    }
  }

  return players.map((p) {
    // Take max of ball-events aggregate or player profile saved stats
    final computedRuns = (ballRuns[p.id] ?? 0) > p.stats.runsScored ? (ballRuns[p.id] ?? 0) : p.stats.runsScored;
    final computedWickets = (ballWickets[p.id] ?? 0) > p.stats.wicketsTaken ? (ballWickets[p.id] ?? 0) : p.stats.wicketsTaken;
    final m = p.stats.matchesPlayed > 0 ? p.stats.matchesPlayed : ((computedRuns > 0 || computedWickets > 0) ? 1 : 0);

    return PlayerTournamentStats(
      player: p,
      teamName: teamNames[p.teamId] ?? 'Independent',
      runs: computedRuns,
      fours: ballFours[p.id] ?? 0,
      sixes: ballSixes[p.id] ?? 0,
      wickets: computedWickets,
      catches: ballCatches[p.id] ?? 0,
      stumps: ballStumps[p.id] ?? 0,
      matches: m,
      highestScore: p.stats.highestScore > 0 ? p.stats.highestScore : computedRuns,
      average: m > 0 ? (computedRuns / m) : 0.0,
    );
  }).toList();
});

// ─── Main Screen ─────────────────────────────────────────────────────────────
class StatsOverviewScreen extends ConsumerStatefulWidget {
  const StatsOverviewScreen({super.key});

  @override
  ConsumerState<StatsOverviewScreen> createState() => _StatsOverviewScreenState();
}

class _StatsOverviewScreenState extends ConsumerState<StatsOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const List<String> _tabs = [
    'MOST RUNS',
    'MOST WICKETS',
    'SIXES & FOURS',
    'FIELDING',
    'ALL PLAYERS',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(tournamentStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'League & Tournament Stats',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 0.3),
            ),
            Text(
              'All Players Leaderboards & Records',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF93C5FD)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Stats',
            onPressed: () => ref.refresh(tournamentStatsProvider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 12),
                Text('Error loading stats: $e', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(tournamentStatsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (allStats) {
          // Filter by search if any
          final filtered = allStats.where((s) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return s.player.name.toLowerCase().contains(q) || s.teamName.toLowerCase().contains(q);
          }).toList();

          // Grand Totals
          final totalPlayers = allStats.length;
          final totalRuns = allStats.fold(0, (sum, s) => sum + s.runs);
          final totalWickets = allStats.fold(0, (sum, s) => sum + s.wickets);
          final totalSixes = allStats.fold(0, (sum, s) => sum + s.sixes);
          final totalFours = allStats.fold(0, (sum, s) => sum + s.fours);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ── 1. GRAND AGGREGATES HEADER ──
              SliverToBoxAdapter(
                child: _buildHeaderHero(totalPlayers, totalRuns, totalWickets, totalSixes, totalFours),
              ),

              // ── 2. SEARCH BAR ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search player or team...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. PINNED CATEGORY TAB BAR ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicator: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                        tabs: _tabs.map((t) => Tab(text: t)).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildRunsTab(filtered),
                _buildWicketsTab(filtered),
                _buildBoundariesTab(filtered),
                _buildFieldingTab(filtered),
                _buildAllPlayersTab(filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER HERO: 4 GRAND AGGREGATES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderHero(int totalPlayers, int totalRuns, int totalWickets, int totalSixes, int totalFours) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'PLAYERS',
                  value: '$totalPlayers',
                  subtext: 'Active in league',
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  bgColor: const Color(0xFF0284C7).withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'TOTAL RUNS',
                  value: '$totalRuns',
                  subtext: 'Scored so far',
                  icon: Icons.sports_cricket_rounded,
                  iconColor: const Color(0xFFFBBF24),
                  bgColor: const Color(0xFFD97706).withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'WICKETS',
                  value: '$totalWickets',
                  subtext: 'Dismissals',
                  icon: Icons.sports_baseball_rounded,
                  iconColor: const Color(0xFFF472B6),
                  bgColor: const Color(0xFFDB2777).withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'BOUNDARIES',
                  value: '${totalFours + totalSixes}',
                  subtext: '$totalFours 4s • $totalSixes 6s',
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFF34D399),
                  bgColor: const Color(0xFF059669).withOpacity(0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: MOST RUNS (ORANGE CAP LEADERBOARD)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRunsTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)..sort((a, b) => b.runs.compareTo(a.runs));
    if (sorted.isEmpty) return _buildEmptyState('No batting stats available yet');

    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        if (top3.isNotEmpty) ...[
          _buildPodium(top3, metricLabel: 'RUNS', getValue: (s) => '${s.runs} R'),
          const SizedBox(height: 16),
        ],
        ...List.generate(sorted.length, (idx) {
          final s = sorted[idx];
          return _buildPlayerStatTile(
            rank: idx + 1,
            stats: s,
            primaryMetric: '${s.runs}',
            primaryLabel: 'RUNS',
            secondaryMetrics: [
              '${s.matches} M',
              '${s.fours} 4s',
              '${s.sixes} 6s',
              'Avg ${s.average.toStringAsFixed(1)}',
            ],
            accentColor: const Color(0xFFD97706),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: MOST WICKETS (PURPLE CAP LEADERBOARD)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWicketsTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)..sort((a, b) => b.wickets.compareTo(a.wickets));
    if (sorted.isEmpty) return _buildEmptyState('No bowling stats available yet');

    final top3 = sorted.take(3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        if (top3.isNotEmpty) ...[
          _buildPodium(top3, metricLabel: 'WICKETS', getValue: (s) => '${s.wickets} W'),
          const SizedBox(height: 16),
        ],
        ...List.generate(sorted.length, (idx) {
          final s = sorted[idx];
          return _buildPlayerStatTile(
            rank: idx + 1,
            stats: s,
            primaryMetric: '${s.wickets}',
            primaryLabel: 'WKTS',
            secondaryMetrics: [
              '${s.matches} M',
              'Best: ${s.player.stats.bestBowling}',
              'Econ: ${s.player.stats.economyRate > 0 ? s.player.stats.economyRate.toStringAsFixed(1) : '-'}',
            ],
            accentColor: const Color(0xFF9333EA),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: MOST BOUNDARIES (SIXES & FOURS)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBoundariesTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)
      ..sort((a, b) => ((b.sixes * 6) + (b.fours * 4)).compareTo((a.sixes * 6) + (a.fours * 4)));
    if (sorted.isEmpty) return _buildEmptyState('No boundary data yet');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: List.generate(sorted.length, (idx) {
        final s = sorted[idx];
        final boundaryRuns = (s.sixes * 6) + (s.fours * 4);
        return _buildPlayerStatTile(
          rank: idx + 1,
          stats: s,
          primaryMetric: '${s.sixes + s.fours}',
          primaryLabel: 'BOUNDARIES',
          secondaryMetrics: [
            '🚀 ${s.sixes} Sixes',
            '🏏 ${s.fours} Fours',
            '$boundaryRuns B-Runs',
          ],
          accentColor: const Color(0xFF059669),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 4: FIELDING & DISMISSALS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFieldingTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)
      ..sort((a, b) => (b.catches + b.stumps).compareTo(a.catches + a.stumps));
    if (sorted.isEmpty) return _buildEmptyState('No fielding data recorded yet');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: List.generate(sorted.length, (idx) {
        final s = sorted[idx];
        return _buildPlayerStatTile(
          rank: idx + 1,
          stats: s,
          primaryMetric: '${s.catches + s.stumps}',
          primaryLabel: 'DISMISSALS',
          secondaryMetrics: [
            '🧤 ${s.catches} Catches',
            '⚡ ${s.stumps} Stumpings',
            '${s.matches} Matches',
          ],
          accentColor: const Color(0xFF0284C7),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 5: ALL PLAYERS DIRECTORY (FULL ROSTER)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAllPlayersTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)
      ..sort((a, b) => a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase()));

    if (sorted.isEmpty) return _buildEmptyState('No players registered yet');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'TOTAL ${sorted.length} PLAYERS REGISTERED',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...List.generate(sorted.length, (idx) {
          final s = sorted[idx];
          final p = s.player;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/players/${p.id}/stats'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Player Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                        image: p.profilePicUrl != null && p.profilePicUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(p.profilePicUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: p.profilePicUrl == null || p.profilePicUrl!.isEmpty
                          ? Text(
                              p.name.substring(0, p.name.length >= 2 ? 2 : 1).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 16),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Player Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.jerseyNumber != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${p.jerseyNumber}',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.teamName,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.role.label.toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF334155), fontSize: 9.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${s.matches} Matches • ${s.runs} Runs • ${s.wickets} Wkts',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PODIUM (TOP 3 PLAYERS SHOWCASE)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPodium(
    List<PlayerTournamentStats> top3, {
    required String metricLabel,
    required String Function(PlayerTournamentStats) getValue,
  }) {
    final rank1 = top3.isNotEmpty ? top3[0] : null;
    final rank2 = top3.length > 1 ? top3[1] : null;
    final rank3 = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 6),
              Text(
                'TOP PERFORMERS PODIUM',
                style: TextStyle(
                  color: Color(0xFFFDE68A),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2 (Silver)
              if (rank2 != null)
                _buildPodiumStep(rank2, rank: 2, color: const Color(0xFF94A3B8), crown: '🥈', getValue: getValue)
              else
                const SizedBox(width: 80),

              // Rank 1 (Gold)
              if (rank1 != null)
                _buildPodiumStep(rank1, rank: 1, color: const Color(0xFFF59E0B), crown: '👑', isGold: true, getValue: getValue),

              // Rank 3 (Bronze)
              if (rank3 != null)
                _buildPodiumStep(rank3, rank: 3, color: const Color(0xFFD97706), crown: '🥉', getValue: getValue)
              else
                const SizedBox(width: 80),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep(
    PlayerTournamentStats s, {
    required int rank,
    required Color color,
    required String crown,
    bool isGold = false,
    required String Function(PlayerTournamentStats) getValue,
  }) {
    final p = s.player;
    return SizedBox(
      width: isGold ? 105 : 90,
      child: Column(
        children: [
          Text(crown, style: TextStyle(fontSize: isGold ? 22 : 18)),
          const SizedBox(height: 2),
          Container(
            width: isGold ? 58 : 48,
            height: isGold ? 58 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color, width: isGold ? 3 : 2),
              image: p.profilePicUrl != null && p.profilePicUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(p.profilePicUrl!), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: p.profilePicUrl == null || p.profilePicUrl!.isEmpty
                ? Text(
                    p.name.substring(0, p.name.length >= 2 ? 2 : 1).toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: isGold ? 18 : 14),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            p.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              getValue(s),
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: isGold ? 12 : 10.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RANKED STAT TILE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPlayerStatTile({
    required int rank,
    required PlayerTournamentStats stats,
    required String primaryMetric,
    required String primaryLabel,
    required List<String> secondaryMetrics,
    required Color accentColor,
  }) {
    final p = stats.player;
    final isTop3 = rank <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isTop3 ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isTop3 ? accentColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/players/${p.id}/stats'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isTop3 ? accentColor : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: isTop3 ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Player Avatar (Small)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  image: p.profilePicUrl != null && p.profilePicUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(p.profilePicUrl!), fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: p.profilePicUrl == null || p.profilePicUrl!.isEmpty
                    ? Text(
                        p.name.substring(0, p.name.length >= 2 ? 2 : 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A), fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats.teamName,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: secondaryMetrics
                          .map(
                            (m) => Text(
                              m,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),

              // Primary Metric Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      primaryMetric,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: accentColor),
                    ),
                    Text(
                      primaryLabel,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 8.5, color: accentColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Sliver Delegate for pinned TabBar ───────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.child);
  final Widget child;

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => true;
}
