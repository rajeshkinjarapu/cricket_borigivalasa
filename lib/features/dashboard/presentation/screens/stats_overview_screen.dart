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
  final playerRepo = ref.read(playerRepositoryProvider);
  final teamRepo = ref.read(teamRepositoryProvider);
  
  final allPlayers = await playerRepo.getAll();
  final allTeams = await teamRepo.getAll();

  // Identify county teams & county team IDs
  final countyTeamIds = allTeams.where((t) => t.isCounty).map((t) => t.id).toSet();
  
  // Filter out county teams and players who strictly belong to county teams
  final players = allPlayers.where((p) => !countyTeamIds.contains(p.teamId)).toList();
  final teams = allTeams.where((t) => !t.isCounty).toList();

  final Map<String, String> teamNames = {
    for (final t in teams) t.id: t.name,
  };

  final sb = Supabase.instance.client;

  // Identify county matches to strictly exclude them from tournament stats
  final Set<String> countyMatchIds = {};
  try {
    final matchesRes = await sb.from('matches').select('id, team_a_id, team_b_id, live_score');
    for (final m in (matchesRes as List)) {
      final mid = m['id']?.toString();
      final live = m['live_score'] as Map<String, dynamic>?;
      final teamAId = m['team_a_id']?.toString();
      final teamBId = m['team_b_id']?.toString();
      final isCounty = (live?['matchType'] == 'county') ||
          (live?['isCounty'] == true) ||
          (teamAId != null && countyTeamIds.contains(teamAId)) ||
          (teamBId != null && countyTeamIds.contains(teamBId));
      if (mid != null && isCounty) {
        countyMatchIds.add(mid);
      }
    }
  } catch (e) {
    debugPrint('Error fetching matches for county filter: $e');
  }

  // Fetch ball-by-ball events for live boundaries, catches, stumps
  List<Map<String, dynamic>> balls = [];
  try {
    final res = await sb.from('ball_events').select(
      'match_id, batter_id, bowler_id, fielder_id, runs_scored, is_boundary, extras_type, wicket_type, player_out_id'
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
  final Map<String, int> ballHighest = {};
  final Map<String, Map<String, int>> matchBatterRuns = {};
  final Map<String, Set<String>> playerMatches = {};

  for (final b in balls) {
    final matchId = b['match_id']?.toString();
    // Exclude county matches completely from tournament stats
    if (matchId != null && countyMatchIds.contains(matchId)) {
      continue;
    }

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
      if (matchId != null) {
        playerMatches.putIfAbsent(batterId, () => {}).add(matchId);
        matchBatterRuns.putIfAbsent(matchId, () => {});
        matchBatterRuns[matchId]![batterId] = (matchBatterRuns[matchId]![batterId] ?? 0) + runsScored;
      }
    }

    if (bowlerId != null) {
      if (matchId != null) {
        playerMatches.putIfAbsent(bowlerId, () => {}).add(matchId);
      }
      if (wicketType != null) {
        final bowlerWickets = ['bowled', 'lbw', 'caught', 'stumped', 'hitWicket'];
        if (bowlerWickets.contains(wicketType)) {
          ballWickets[bowlerId] = (ballWickets[bowlerId] ?? 0) + 1;
        }
      }
    }

    if (fielderId != null) {
      if (matchId != null) {
        playerMatches.putIfAbsent(fielderId, () => {}).add(matchId);
      }
      if (wicketType == 'caught') {
        ballCatches[fielderId] = (ballCatches[fielderId] ?? 0) + 1;
      }
      if (wicketType == 'stumped') {
        ballStumps[fielderId] = (ballStumps[fielderId] ?? 0) + 1;
      }
    }
  }

  // Calculate highest score in a single non-county tournament match
  for (final matchRuns in matchBatterRuns.values) {
    for (final entry in matchRuns.entries) {
      final pId = entry.key;
      final r = entry.value;
      if (r > (ballHighest[pId] ?? 0)) {
        ballHighest[pId] = r;
      }
    }
  }

  return players.map((p) {
    final computedRuns = ballRuns[p.id] ?? 0;
    final computedWickets = ballWickets[p.id] ?? 0;
    final m = playerMatches[p.id]?.length ?? 0;
    final highest = ballHighest[p.id] ?? 0;

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
      highestScore: highest,
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'League & Tournament Stats',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
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

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ── 1. SEARCH BAR ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search player or team...',
                        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF1E3A8A)),
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

              // ── 2. PINNED CATEGORY TAB BAR (Starts directly from left) ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  Container(
                    color: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: EdgeInsets.zero,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.3),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
  // TAB 1: MOST RUNS (ORANGE CAP LEADERBOARD)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRunsTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)..sort((a, b) => b.runs.compareTo(a.runs));
    if (sorted.isEmpty) return _buildEmptyState('No batting stats available yet');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
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
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: MOST WICKETS (PURPLE CAP LEADERBOARD)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWicketsTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)..sort((a, b) => b.wickets.compareTo(a.wickets));
    if (sorted.isEmpty) return _buildEmptyState('No bowling stats available yet');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
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
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: MOST BOUNDARIES (SIXES & FOURS)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBoundariesTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)
      ..sort((a, b) => ((b.sixes * 6) + (b.fours * 4)).compareTo((a.sixes * 6) + (a.fours * 4)));
    if (sorted.isEmpty) return _buildEmptyState('No boundary data yet');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
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
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 4: FIELDING & DISMISSALS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFieldingTab(List<PlayerTournamentStats> list) {
    final sorted = List<PlayerTournamentStats>.from(list)
      ..sort((a, b) => (b.catches + b.stumps).compareTo(a.catches + a.stumps));
    if (sorted.isEmpty) return _buildEmptyState('No fielding data recorded yet');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
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
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
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
                            (s.teamName.isNotEmpty &&
                                    s.teamName.toLowerCase() != p.name.toLowerCase() &&
                                    s.teamName != 'Independent')
                                ? s.teamName
                                : p.role.label,
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
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isTop3 ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isTop3 ? accentColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/players/${p.id}/stats'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Player Avatar (Square)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  image: p.profilePicUrl != null && p.profilePicUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(p.profilePicUrl!), fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: p.profilePicUrl == null || p.profilePicUrl!.isEmpty
                    ? Text(
                        p.name.substring(0, p.name.length >= 2 ? 2 : 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Player Info
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Primary Metric Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
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
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => true;
}
