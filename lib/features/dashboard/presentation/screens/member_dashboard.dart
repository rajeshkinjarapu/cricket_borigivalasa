import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../../core/utils/avatar_helper.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../matches/data/models/match.dart';
import '../../../scoring/data/models/innings.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/app_drawer.dart';

// ─── Model for Player's Per-Match Breakdown ──────────────────────────────────
class PlayerMatchDetail {
  final Match match;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final int wickets;
  final bool isWin;
  final bool isMoM;

  const PlayerMatchDetail({
    required this.match,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.wickets = 0,
    this.isWin = false,
    this.isMoM = false,
  });
}

// ─── Provider for Player's Detailed Match Stats ──────────────────────────────
final playerDetailedPerformanceProvider =
    FutureProvider<List<PlayerMatchDetail>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final loggedInPlayer = ref.watch(loggedInPlayerProvider).value;
  final playerId = loggedInPlayer?.id ?? user.uid;
  final playerName = loggedInPlayer?.name ?? user.displayName;
  final playerTeamId = loggedInPlayer?.teamId ?? '';
  final playerTeamIds = loggedInPlayer?.teamIds ?? [];

  final sb = Supabase.instance.client;

  // 1. Fetch matches
  List<Match> allMatches = [];
  try {
    final matchesRes = await sb.from('matches').select();
    allMatches = (matchesRes as List)
        .map((m) => Match.fromJson(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    allMatches = [];
  }

  // 2. Fetch ball events for this player
  List<Map<String, dynamic>> balls = [];
  try {
    final res = await sb.from('ball_events').select(
        'match_id, batter_id, bowler_id, runs_scored, is_boundary, wicket_type');
    balls = List<Map<String, dynamic>>.from(res);
  } catch (_) {
    balls = [];
  }

  final Map<String, int> matchRuns = {};
  final Map<String, int> matchBalls = {};
  final Map<String, int> matchFours = {};
  final Map<String, int> matchSixes = {};
  final Map<String, int> matchWickets = {};
  final Set<String> playedMatchIds = {};

  for (final b in balls) {
    final mid = b['match_id']?.toString();
    if (mid == null) continue;

    final batterId = b['batter_id']?.toString();
    final bowlerId = b['bowler_id']?.toString();
    final runs = b['runs_scored'] as int? ?? 0;
    final isBoundary = b['is_boundary'] as bool? ?? false;
    final wicketType = b['wicket_type'] as String?;

    if (batterId == playerId) {
      playedMatchIds.add(mid);
      matchRuns[mid] = (matchRuns[mid] ?? 0) + runs;
      matchBalls[mid] = (matchBalls[mid] ?? 0) + 1;
      if (isBoundary && runs == 4) {
        matchFours[mid] = (matchFours[mid] ?? 0) + 1;
      }
      if (isBoundary && runs == 6) {
        matchSixes[mid] = (matchSixes[mid] ?? 0) + 1;
      }
    }

    if (bowlerId == playerId) {
      playedMatchIds.add(mid);
      if (wicketType != null) {
        final bowlerWickets = [
          'bowled',
          'lbw',
          'caught',
          'stumped',
          'hitWicket'
        ];
        if (bowlerWickets.contains(wicketType)) {
          matchWickets[mid] = (matchWickets[mid] ?? 0) + 1;
        }
      }
    }
  }

  final List<PlayerMatchDetail> list = [];

  for (final m in allMatches) {
    final isPlayerInMatch = playedMatchIds.contains(m.id) ||
        (playerTeamId.isNotEmpty &&
            (m.teamAId == playerTeamId || m.teamBId == playerTeamId)) ||
        (playerTeamIds.isNotEmpty &&
            (playerTeamIds.contains(m.teamAId) ||
                playerTeamIds.contains(m.teamBId)));

    if (!isPlayerInMatch) continue;

    final bool isWin = m.winnerTeamId != null &&
        (m.winnerTeamId == playerTeamId ||
            playerTeamIds.contains(m.winnerTeamId));
    final bool isMoM = (m.manOfTheMatchId != null &&
            m.manOfTheMatchId == playerId) ||
        (m.manOfTheMatchName != null &&
            m.manOfTheMatchName!.trim().toLowerCase() ==
                playerName.trim().toLowerCase());

    list.add(PlayerMatchDetail(
      match: m,
      runs: matchRuns[m.id] ?? 0,
      balls: matchBalls[m.id] ?? 0,
      fours: matchFours[m.id] ?? 0,
      sixes: matchSixes[m.id] ?? 0,
      wickets: matchWickets[m.id] ?? 0,
      isWin: isWin,
      isMoM: isMoM,
    ));
  }

  list.sort((a, b) => b.match.matchDate.compareTo(a.match.matchDate));
  return list;
});

class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider);
    final isScorer = u?.role == UserRole.scorer;

    final allMatchesAsync = ref.watch(allMatchesProvider);
    final loggedInPlayer = ref.watch(loggedInPlayerProvider).value;
    final detailedPerfAsync = ref.watch(playerDetailedPerformanceProvider);
    final detailedPerfList = detailedPerfAsync.value ?? [];

    // Compute aggregated player stats
    final int fallbackPlayed = loggedInPlayer?.stats.matchesPlayed ?? 0;
    final int fallbackRuns = loggedInPlayer?.stats.runsScored ?? 0;
    final int fallbackWickets = loggedInPlayer?.stats.wicketsTaken ?? 0;

    final int matchesPlayed = detailedPerfList.isNotEmpty
        ? detailedPerfList.length
        : fallbackPlayed;

    final int totalRuns = detailedPerfList.isNotEmpty
        ? detailedPerfList.fold(0, (sum, item) => sum + item.runs)
        : fallbackRuns;

    final int totalWickets = detailedPerfList.isNotEmpty
        ? detailedPerfList.fold(0, (sum, item) => sum + item.wickets)
        : fallbackWickets;

    final int totalFours =
        detailedPerfList.fold(0, (sum, item) => sum + item.fours);
    final int totalSixes =
        detailedPerfList.fold(0, (sum, item) => sum + item.sixes);
    final int matchesWon =
        detailedPerfList.where((item) => item.isWin).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: const AppDrawer(),
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
        title: const Text(
          'Member Dashboard',
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
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              ref.refresh(playerDetailedPerformanceProvider);
              ref.refresh(allMatchesProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── Profile Info Card ──
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFF38BDF8), width: 2.5),
                        color: Colors.white.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: getAppAvatarProvider(u?.photoUrl) != null
                            ? DecorationImage(
                                image: getAppAvatarProvider(u?.photoUrl)!,
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: getAppAvatarProvider(u?.photoUrl) == null
                          ? Center(
                              child: Text(
                                (u?.displayName.isNotEmpty ?? false)
                                    ? u!.displayName[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u?.displayName ?? 'Member',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isScorer
                                ? const Color(0xFF10B981).withOpacity(0.2)
                                : const Color(0xFF38BDF8).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isScorer
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF38BDF8),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isScorer
                                    ? Icons.verified_rounded
                                    : Icons.sports_cricket_rounded,
                                color: isScorer
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFBAE6FD),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isScorer ? 'SCORER' : 'MEMBER',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isScorer
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFBAE6FD),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── TODAY'S MATCHES / LAST MATCH SECTION ──
            allMatchesAsync.when(
              data: (matches) {
                final now = DateTime.now();
                final sortedMatches = List<Match>.from(matches)
                  ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

                final todayMatches = sortedMatches.where((m) {
                  return m.matchDate.year == now.year &&
                      m.matchDate.month == now.month &&
                      m.matchDate.day == now.day;
                }).toList();

                final bool hasTodayMatches = todayMatches.isNotEmpty;
                final displayMatches = hasTodayMatches
                    ? [todayMatches.first]
                    : (sortedMatches.isNotEmpty ? [sortedMatches.first] : <Match>[]);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasTodayMatches
                                  ? Icons.calendar_today_rounded
                                  : Icons.history_rounded,
                              size: 16,
                              color: const Color(0xFF1E3A8A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasTodayMatches ? "TODAY'S MATCH" : "LAST MATCH",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/matches-list'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (displayMatches.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No matches found',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      )
                    else
                      ...displayMatches.map((m) {
                        return _TodayMatchCard(
                          match: m,
                          isTodayMatch: hasTodayMatches,
                        );
                      }),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error loading matches: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 24),

            // ── 6 STATS CARDS (3 CARDS PER ROW) ──
            const Row(
              children: [
                Icon(Icons.analytics_rounded,
                    size: 16, color: Color(0xFF1E3A8A)),
                SizedBox(width: 6),
                Text(
                  'MY PERFORMANCE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.04,
              children: [
                // 1. Matches Played
                _StatCard(
                  emoji: '🏏',
                  label: 'Matches Played',
                  value: '$matchesPlayed',
                  accentColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () {
                    _showPerformanceSheet(
                      context: context,
                      title: 'Matches Played',
                      totalCount: '$matchesPlayed Matches',
                      accentColor: const Color(0xFF2563EB),
                      items: detailedPerfList,
                      type: 'matches',
                    );
                  },
                ),

                // 2. Matches Won
                _StatCard(
                  emoji: '🏆',
                  label: 'Matches Won',
                  value: '$matchesWon',
                  accentColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                  onTap: () {
                    final wonList =
                        detailedPerfList.where((item) => item.isWin).toList();
                    _showPerformanceSheet(
                      context: context,
                      title: 'Matches Won',
                      totalCount: '$matchesWon Victories',
                      accentColor: const Color(0xFFD97706),
                      items: wonList,
                      type: 'won',
                    );
                  },
                ),

                // 3. Total Runs
                _StatCard(
                  emoji: '🎯',
                  label: 'Total Runs',
                  value: '$totalRuns',
                  accentColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  onTap: () {
                    final runsList = List<PlayerMatchDetail>.from(
                        detailedPerfList)
                      ..sort((a, b) => b.runs.compareTo(a.runs));
                    _showPerformanceSheet(
                      context: context,
                      title: 'Match-wise Runs',
                      totalCount: '$totalRuns Total Runs',
                      accentColor: const Color(0xFF059669),
                      items: runsList,
                      type: 'runs',
                    );
                  },
                ),

                // 4. Total Wickets
                _StatCard(
                  emoji: '🎳',
                  label: 'Total Wickets',
                  value: '$totalWickets',
                  accentColor: const Color(0xFF9333EA),
                  bgColor: const Color(0xFFFAF5FF),
                  onTap: () {
                    final wktList = List<PlayerMatchDetail>.from(
                        detailedPerfList)
                      ..sort((a, b) => b.wickets.compareTo(a.wickets));
                    _showPerformanceSheet(
                      context: context,
                      title: 'Match-wise Wickets',
                      totalCount: '$totalWickets Total Wickets',
                      accentColor: const Color(0xFF9333EA),
                      items: wktList,
                      type: 'wickets',
                    );
                  },
                ),

                // 5. Total Fours
                _StatCard(
                  emoji: '💥',
                  label: 'Total Fours',
                  value: '$totalFours',
                  accentColor: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                  onTap: () {
                    final foursList = List<PlayerMatchDetail>.from(
                        detailedPerfList)
                      ..sort((a, b) => b.fours.compareTo(a.fours));
                    _showPerformanceSheet(
                      context: context,
                      title: 'Fours Breakdown',
                      totalCount: '$totalFours Fours Hit',
                      accentColor: const Color(0xFF0284C7),
                      items: foursList,
                      type: 'fours',
                    );
                  },
                ),

                // 6. Total Sixes
                _StatCard(
                  emoji: '🚀',
                  label: 'Total Sixes',
                  value: '$totalSixes',
                  accentColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: () {
                    final sixesList = List<PlayerMatchDetail>.from(
                        detailedPerfList)
                      ..sort((a, b) => b.sixes.compareTo(a.sixes));
                    _showPerformanceSheet(
                      context: context,
                      title: 'Sixes Breakdown',
                      totalCount: '$totalSixes Sixes Hit',
                      accentColor: const Color(0xFFDC2626),
                      items: sixesList,
                      type: 'sixes',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DETAILED MODAL BOTTOM SHEET FOR PERFORMANCE CARDS
  // ─────────────────────────────────────────────────────────────────────────
  void _showPerformanceSheet({
    required BuildContext context,
    required String title,
    required String totalCount,
    required Color accentColor,
    required List<PlayerMatchDetail> items,
    required String type,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalCount,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // List of Matches
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_cricket_outlined,
                                  size: 48, color: const Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(
                                'No records found yet for this metric.',
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          final m = item.match;

                          String metricValueText = '';
                          String metricSubtitleText = '';

                          if (type == 'runs') {
                            metricValueText = '${item.runs} Runs';
                            metricSubtitleText =
                                '${item.balls} balls • ${item.fours} 4s • ${item.sixes} 6s';
                          } else if (type == 'wickets') {
                            metricValueText = '${item.wickets} Wkts';
                            metricSubtitleText = 'Bowling spell';
                          } else if (type == 'fours') {
                            metricValueText = '${item.fours} 4s';
                            metricSubtitleText = '${item.runs} total runs';
                          } else if (type == 'sixes') {
                            metricValueText = '${item.sixes} 6s';
                            metricSubtitleText = '${item.runs} total runs';
                          } else if (type == 'won') {
                            metricValueText = '🏆 Won';
                            metricSubtitleText = m.resultText ?? 'Match Completed';
                          } else {
                            metricValueText = '${item.runs}r • ${item.wickets}w';
                            metricSubtitleText = m.status.label;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            color: Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.pop(ctx);
                                if (m.tournamentId.isNotEmpty) {
                                  if (m.isCompleted) {
                                    context.push(
                                        '/tournaments/${m.tournamentId}/matches/${m.id}/summary');
                                  } else {
                                    context.push(
                                        '/tournaments/${m.tournamentId}/matches/${m.id}');
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    // Match Icon Badge
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.sports_cricket_rounded,
                                        size: 18,
                                        color: accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Teams & Date
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${m.teamA} vs ${m.teamB}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            DateFormat('MMM dd, yyyy • hh:mm a')
                                                .format(m.matchDate),
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (metricSubtitleText.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              metricSubtitleText,
                                              style: TextStyle(
                                                color: Color(0xFF475569),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Metric Score Chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: accentColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        metricValueText,
                                        style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Today / Recent Match Card Item with Scores & Result ──────────────────────
class _TodayMatchCard extends ConsumerWidget {
  final Match match;
  final bool isTodayMatch;

  const _TodayMatchCard({
    required this.match,
    this.isTodayMatch = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = match;
    final isLive = m.status == MatchStatus.live;
    final isCompleted = m.status == MatchStatus.completed;

    // Fetch innings data if tournamentId and match id exist
    final i1 = m.tournamentId.isNotEmpty
        ? ref.watch(inningsProvider(
            (tournamentId: m.tournamentId, matchId: m.id, innings: 1))).value
        : null;
    final i2 = m.tournamentId.isNotEmpty
        ? ref.watch(inningsProvider(
            (tournamentId: m.tournamentId, matchId: m.id, innings: 2))).value
        : null;

    final bool isCounty = m.liveScore?['matchType'] == 'county' ||
        m.liveScore?['isCounty'] == true ||
        m.tournamentId == 'county_matches';

    // Map innings to team A and team B
    Innings? teamAInn;
    Innings? teamBInn;
    if (i1 != null) {
      if (i1.battingTeamId == m.teamAId) {
        teamAInn = i1;
      } else if (i1.battingTeamId == m.teamBId) {
        teamBInn = i1;
      }
    }
    if (i2 != null) {
      if (i2.battingTeamId == m.teamAId) {
        teamAInn = i2;
      } else if (i2.battingTeamId == m.teamBId) {
        teamBInn = i2;
      }
    }
    if (isCounty && teamAInn == null && i1 != null) {
      teamAInn = i1;
    }

    // Extract score strings
    String? scoreA;
    String? scoreB;

    if (teamAInn != null &&
        (teamAInn.legalBalls > 0 || teamAInn.runs > 0 || isCompleted)) {
      scoreA = '${teamAInn.runs}/${teamAInn.wickets} (${teamAInn.oversText} ov)';
    } else if (m.liveScore != null && m.liveScore!['inn1'] != null) {
      final inn1 = m.liveScore!['inn1'] as Map<String, dynamic>;
      final runs = inn1['runs'] ?? 0;
      final wkts = inn1['wickets'] ?? 0;
      final ov = inn1['overs'] ?? '0.0';
      if (runs > 0 || wkts > 0 || isCompleted) {
        scoreA = '$runs/$wkts ($ov ov)';
      }
    } else if (isCounty &&
        m.liveScore != null &&
        (m.liveScore!['runs'] != null || isCompleted)) {
      final runs = m.liveScore!['runs'] ?? 0;
      final wkts = m.liveScore!['wickets'] ?? 0;
      final ov = m.liveScore!['overs'] ?? '0.0';
      scoreA = '$runs/$wkts ($ov ov)';
    }

    if (!isCounty) {
      if (teamBInn != null &&
          (teamBInn.legalBalls > 0 || teamBInn.runs > 0 || isCompleted)) {
        scoreB = '${teamBInn.runs}/${teamBInn.wickets} (${teamBInn.oversText} ov)';
      } else if (m.liveScore != null && m.liveScore!['inn2'] != null) {
        final inn2 = m.liveScore!['inn2'] as Map<String, dynamic>;
        final runs = inn2['runs'] ?? 0;
        final wkts = inn2['wickets'] ?? 0;
        final ov = inn2['overs'] ?? '0.0';
        if (runs > 0 || wkts > 0 || isCompleted) {
          scoreB = '$runs/$wkts ($ov ov)';
        }
      }
    }

    // Calculate Result Banner (Only show winner or live target, avoiding redundant info)
    String? resultText;
    if (i1 != null && i2 != null && (i2.isComplete || isCompleted)) {
      if (i2.runs > i1.runs) {
        final remWickets = 10 - i2.wickets;
        final winnerName = teamBInn == i2 ? m.teamB : m.teamA;
        resultText =
            '$winnerName won by $remWickets ${remWickets == 1 ? 'wicket' : 'wickets'}';
      } else if (i1.runs > i2.runs) {
        final remRuns = i1.runs - i2.runs;
        final winnerName = teamAInn == i1 ? m.teamA : m.teamB;
        resultText =
            '$winnerName won by $remRuns ${remRuns == 1 ? 'run' : 'runs'}';
      } else if (i1.runs == i2.runs) {
        resultText = 'Match Tied';
      }
    } else if (m.winnerTeamId != null && m.winnerTeamId!.isNotEmpty) {
      final winnerName = m.teamNameById(m.winnerTeamId);
      resultText = '$winnerName won';
    } else if (m.resultText != null &&
        m.resultText!.trim().isNotEmpty &&
        !m.resultText!.toLowerCase().contains('match completed') &&
        !m.resultText!.toLowerCase().contains('scored')) {
      resultText = m.resultText!.trim();
    } else if (m.liveScore?['result'] != null &&
        m.liveScore!['result'].toString().trim().isNotEmpty &&
        !m.liveScore!['result'].toString().toLowerCase().contains('match completed') &&
        !m.liveScore!['result'].toString().toLowerCase().contains('scored')) {
      resultText = m.liveScore!['result'].toString().trim();
    } else if (isLive &&
        !isCounty &&
        i1 != null &&
        i1.isComplete &&
        i2 != null &&
        !i2.isComplete) {
      final target = i1.runs + 1;
      final needed = target - i2.runs;
      final remBalls = (m.totalOvers * 6) - i2.legalBalls;
      final chasingTeam = teamBInn == i2 ? m.teamB : m.teamA;
      if (needed > 0 && remBalls >= 0) {
        resultText = '$chasingTeam need $needed runs in $remBalls balls';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFFEF4444).withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (m.tournamentId.isNotEmpty) {
            if (isCompleted) {
              context.push(
                  '/tournaments/${m.tournamentId}/matches/${m.id}/summary');
            } else {
              context.push('/tournaments/${m.tournamentId}/matches/${m.id}');
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row: Date/Time & Status Badge ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLive
                            ? Icons.fiber_manual_record_rounded
                            : Icons.access_time_filled_rounded,
                        size: isLive ? 12 : 14,
                        color: isLive
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isTodayMatch
                            ? DateFormat('hh:mm a').format(m.matchDate)
                            : DateFormat('MMM dd, hh:mm a').format(m.matchDate),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: isLive
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLive
                          ? const Color(0xFFFEF2F2)
                          : isCompleted
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLive
                            ? const Color(0xFFFECACA)
                            : isCompleted
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFDBEAFE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted) ...[
                          const Icon(Icons.check_circle_rounded,
                              size: 11, color: Color(0xFF059669)),
                          const SizedBox(width: 3.5),
                        ],
                        Text(
                          isLive
                              ? 'LIVE'
                              : (isCompleted ? 'COMPLETED' : 'SCHEDULED'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                            color: isLive
                                ? const Color(0xFFDC2626)
                                : isCompleted
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF1D4ED8),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Team A Row with Score ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      m.teamA.isNotEmpty
                          ? m.teamA.substring(0, 1).toUpperCase()
                          : 'A',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.teamA,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (scoreA != null)
                    Text(
                      scoreA,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Team B Row with Score ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isCounty
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFDF2F8),
                    child: Text(
                      m.teamB.isNotEmpty
                          ? m.teamB.substring(0, 1).toUpperCase()
                          : 'B',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: isCounty
                            ? const Color(0xFFB45309)
                            : const Color(0xFF9D174D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.teamB,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (scoreB != null)
                    Text(
                      scoreB,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A8A),
                      ),
                    )
                  else if (isCounty)
                    const Text(
                      'Opponent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),

              // ── Result Banner (Winner / Live Target) ──
              if (resultText != null && resultText.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.emoji_events_rounded
                            : Icons.info_outline_rounded,
                        size: 14,
                        color: isCompleted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          resultText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCompleted
                                ? const Color(0xFF15803D)
                                : const Color(0xFF475569),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Footer: Match Stage & Overs ──
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_cricket_rounded,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        isCounty
                            ? 'County Match • ${m.totalOvers} Overs'
                            : (m.matchNumber != null
                                ? 'Match #${m.matchNumber} • ${m.totalOvers} Overs'
                                : 'League Match • ${m.totalOvers} Overs'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Individual Performance Metric Card ──────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          colors: [
            Colors.white,
            bgColor.withOpacity(0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Emoji Icon on top-left + subtle arrow on top-right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: accentColor.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),

                // Big Bold Centered Number
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: accentColor,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                // Card Label Centered
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                    letterSpacing: 0.1,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
