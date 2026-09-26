import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class _PlayerLeaderStats {
  final Player player;
  final int runs;
  final int fours;
  final int sixes;
  final int wickets;
  final int catches;
  final int stumps;
  final int matches;
  final int highestScore;
  final double average;

  const _PlayerLeaderStats({
    required this.player,
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

// ─── Provider ────────────────────────────────────────────────────────────────
final _leaderboardProvider = FutureProvider<List<_PlayerLeaderStats>>((ref) async {
  final allPlayers = await ref.watch(allPlayersProvider.future);
  final sb = Supabase.instance.client;

  // Identify county teams
  final teamsRes = await sb.from('teams').select('id, is_county');
  final Set<String> countyTeamIds = {};
  for (final t in (teamsRes as List)) {
    if (t['is_county'] == true) {
      countyTeamIds.add(t['id'].toString());
    }
  }

  // Filter players
  final players = allPlayers.where((p) => !countyTeamIds.contains(p.teamId)).toList();

  // Identify county matches
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
  } catch (_) {}

  // Fetch all ball_events once
  final balls = await sb.from('ball_events').select(
    'match_id, batter_id, bowler_id, fielder_id, runs_scored, is_boundary, extras_type, wicket_type, player_out_id'
  );

  // Compute per-player aggregates
  final Map<String, int> runs = {};
  final Map<String, int> fours = {};
  final Map<String, int> sixes = {};
  final Map<String, int> wickets = {};
  final Map<String, int> catches = {};
  final Map<String, int> stumps = {};
  final Map<String, Set<String>> playerMatches = {};

  for (final b in balls) {
    final matchId = b['match_id']?.toString();
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
      runs[batterId] = (runs[batterId] ?? 0) + runsScored;
      if (isBoundary && runsScored == 4) {
        fours[batterId] = (fours[batterId] ?? 0) + 1;
      }
      if (isBoundary && runsScored == 6) {
        sixes[batterId] = (sixes[batterId] ?? 0) + 1;
      }
      if (matchId != null) playerMatches.putIfAbsent(batterId, () => {}).add(matchId);
    }

    if (bowlerId != null) {
      if (matchId != null) playerMatches.putIfAbsent(bowlerId, () => {}).add(matchId);
      if (wicketType != null) {
        final bowlerWickets = ['bowled', 'lbw', 'caught', 'stumped', 'hitWicket'];
        if (bowlerWickets.contains(wicketType)) {
          wickets[bowlerId] = (wickets[bowlerId] ?? 0) + 1;
        }
      }
    }

    if (fielderId != null) {
      if (matchId != null) playerMatches.putIfAbsent(fielderId, () => {}).add(matchId);
      if (wicketType == 'caught') {
        catches[fielderId] = (catches[fielderId] ?? 0) + 1;
      }
      if (wicketType == 'stumped') {
        stumps[fielderId] = (stumps[fielderId] ?? 0) + 1;
      }
    }
  }

  return players.map((p) {
    final r = runs[p.id] ?? 0;
    final m = playerMatches[p.id]?.length ?? 0;
    return _PlayerLeaderStats(
      player: p,
      runs: r,
      fours: fours[p.id] ?? 0,
      sixes: sixes[p.id] ?? 0,
      wickets: wickets[p.id] ?? 0,
      catches: catches[p.id] ?? 0,
      stumps: stumps[p.id] ?? 0,
      matches: m,
      highestScore: p.stats.highestScore,
      average: m > 0 ? r / m : 0,
    );
  }).toList();
});

// ─── Screen ──────────────────────────────────────────────────────────────────
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _tabs = ['RUNS', 'WICKETS', 'FOURS', 'SIXES', 'CATCHES'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_leaderboardProvider);

    return Column(
      children: [
        // Tab bar for leaderboard categories
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            indicatorColor: const Color(0xFF1B4332),
            indicatorWeight: 3,
            labelColor: const Color(0xFF1B4332),
            unselectedLabelColor: const Color(0xFF94A3B8),
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332))),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              if (all.isEmpty) return _buildEmpty();
              return TabBarView(
                controller: _tab,
                children: [
                  _buildList(all, 'RUNS'),
                  _buildList(all, 'WICKETS'),
                  _buildList(all, 'FOURS'),
                  _buildList(all, 'SIXES'),
                  _buildList(all, 'CATCHES'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<_PlayerLeaderStats> _sorted(List<_PlayerLeaderStats> all, String tab) {
    final copy = [...all];
    switch (tab) {
      case 'RUNS':    copy.sort((a, b) => b.runs.compareTo(a.runs)); break;
      case 'WICKETS': copy.sort((a, b) => b.wickets.compareTo(a.wickets)); break;
      case 'FOURS':   copy.sort((a, b) => b.fours.compareTo(a.fours)); break;
      case 'SIXES':   copy.sort((a, b) => b.sixes.compareTo(a.sixes)); break;
      case 'CATCHES': copy.sort((a, b) => b.catches.compareTo(a.catches)); break;
    }
    return copy;
  }

  Widget _buildList(List<_PlayerLeaderStats> all, String tab) {
    final sorted = _sorted(all, tab);
    return Column(
      children: [
        _buildSummaryStrip(all, tab),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) => _buildPlayerCard(sorted[i], i, tab),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip(List<_PlayerLeaderStats> all, String tab) {
    final sorted = _sorted(all, tab);
    final top = sorted.isNotEmpty ? sorted.first : null;
    if (top == null) return const SizedBox.shrink();

    final colors = {
      'RUNS':    const Color(0xFF2563EB),
      'WICKETS': const Color(0xFFDC2626),
      'FOURS':   const Color(0xFFD97706),
      'SIXES':   const Color(0xFF7C3AED),
      'CATCHES': const Color(0xFF059669),
    };
    final col = colors[tab] ?? Colors.blueGrey;
    final val = _statValue(top, tab);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [col, col.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: col.withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2.5),
            ),
            child: Center(
              child: Text(
                top.player.name.isNotEmpty ? top.player.name[0].toUpperCase() : 'P',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: col),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text('LEADER', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(top.player.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(top.player.role.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$val', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              Text(tab, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(_PlayerLeaderStats p, int rank, String tab) {
    final medals = [Colors.amber, const Color(0xFFB0BEC5), const Color(0xFFCD7F32)];
    final isMedal = rank < 3;
    final medalColor = isMedal ? medals[rank] : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMedal
            ? Border.all(color: medalColor.withOpacity(0.5), width: 1.5)
            : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isMedal ? medalColor.withOpacity(0.12) : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isMedal ? medalColor.withOpacity(0.15) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isMedal
                    ? Icon(Icons.emoji_events_rounded, size: 18, color: medalColor)
                    : Text('#${rank + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Center(
                child: Text(
                  p.player.name.isNotEmpty ? p.player.name[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + Role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.player.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(p.player.role.label,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            ),

            // Key stat + secondary stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${_statValue(p, tab)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                _buildMiniStats(p, tab),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStats(_PlayerLeaderStats p, String tab) {
    // Show secondary stats depending on which leaderboard we are in
    List<String> items;
    switch (tab) {
      case 'RUNS':
        items = ['${p.fours} 4s', '${p.sixes} 6s', '${p.matches}M'];
        break;
      case 'WICKETS':
        items = ['${p.catches} ct', '${p.stumps} st', '${p.matches}M'];
        break;
      case 'FOURS':
        items = ['${p.runs} runs', '${p.sixes} 6s'];
        break;
      case 'SIXES':
        items = ['${p.runs} runs', '${p.fours} 4s'];
        break;
      default:
        items = ['${p.stumps} st', '${p.matches}M'];
    }
    return Row(
      children: items
          .map((s) => Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              ))
          .toList(),
    );
  }

  int _statValue(_PlayerLeaderStats p, String tab) {
    switch (tab) {
      case 'RUNS':    return p.runs;
      case 'WICKETS': return p.wickets;
      case 'FOURS':   return p.fours;
      case 'SIXES':   return p.sixes;
      case 'CATCHES': return p.catches;
      default:        return 0;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No player stats yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          const Text('Stats will appear after matches are played', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
