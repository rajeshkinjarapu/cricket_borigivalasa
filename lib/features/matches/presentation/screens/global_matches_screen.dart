import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../scoring/data/models/innings.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../data/models/match.dart';

class GlobalMatchesScreen extends ConsumerStatefulWidget {
  const GlobalMatchesScreen({super.key});

  @override
  ConsumerState<GlobalMatchesScreen> createState() => _GlobalMatchesScreenState();
}

class _GlobalMatchesScreenState extends ConsumerState<GlobalMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveMatchesAsync = ref.watch(liveMatchesProvider);
    final upcomingMatchesAsync = ref.watch(upcomingMatchesProvider);
    final allMatchesAsync = ref.watch(allMatchesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canScore = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.scorer;

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
          'Matches',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(liveMatchesProvider);
              ref.invalidate(upcomingMatchesProvider);
              ref.invalidate(allMatchesProvider);
            },
          ),
          if (canScore)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              tooltip: 'Create Match',
              onPressed: () => context.push('/matches/new'),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // ── Clean Pinned Tab Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Live'),
                        ],
                      ),
                    ),
                  ),
                  const Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 15),
                          SizedBox(width: 5),
                          Text('Upcoming'),
                        ],
                      ),
                    ),
                  ),
                  const Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 15),
                          SizedBox(width: 5),
                          Text('All Matches'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Live Tab
                liveMatchesAsync.when(
                  data: (matches) => _buildMatchList(
                    context,
                    matches,
                    emptyMsg: 'No live matches in progress right now.',
                    emptyIcon: Icons.sports_cricket_rounded,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error loading live matches: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ),

                // 2. Upcoming Tab
                upcomingMatchesAsync.when(
                  data: (matches) => _buildMatchList(
                    context,
                    matches,
                    emptyMsg: 'No upcoming fixtures scheduled yet.',
                    emptyIcon: Icons.calendar_month_outlined,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error loading upcoming matches: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ),

                // 3. All Matches Tab
                allMatchesAsync.when(
                  data: (matches) => _buildMatchList(
                    context,
                    matches,
                    emptyMsg: 'No matches found.',
                    emptyIcon: Icons.sports_score_rounded,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error loading matches: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canScore
          ? FloatingActionButton.extended(
              heroTag: 'fab_global_matches',
              onPressed: () => context.push('/matches/new'),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create Match',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            )
          : null,
    );
  }

  Widget _buildMatchList(
    BuildContext context,
    List<Match> matches, {
    required String emptyMsg,
    required IconData emptyIcon,
  }) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                child: Icon(emptyIcon, size: 48, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final m = matches[index];
        return _MatchCardItem(match: m);
      },
    );
  }
}

// ─── Individual Match Card with Live Score & Result Extraction ───────────────
class _MatchCardItem extends ConsumerWidget {
  const _MatchCardItem({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = match;
    final isLive = m.status == MatchStatus.live;
    final isCompleted = m.status == MatchStatus.completed;

    // Fetch innings data if tournamentId and match id exist
    final i1 = m.tournamentId.isNotEmpty
        ? ref.watch(inningsProvider((tournamentId: m.tournamentId, matchId: m.id, innings: 1))).value
        : null;
    final i2 = m.tournamentId.isNotEmpty
        ? ref.watch(inningsProvider((tournamentId: m.tournamentId, matchId: m.id, innings: 2))).value
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

    if (teamAInn != null && (teamAInn.legalBalls > 0 || teamAInn.runs > 0 || isCompleted)) {
      scoreA = '${teamAInn.runs}/${teamAInn.wickets} (${teamAInn.oversText} ov)';
    } else if (m.liveScore != null && m.liveScore!['inn1'] != null) {
      final inn1 = m.liveScore!['inn1'] as Map<String, dynamic>;
      final runs = inn1['runs'] ?? 0;
      final wkts = inn1['wickets'] ?? 0;
      final ov = inn1['overs'] ?? '0.0';
      if (runs > 0 || wkts > 0 || isCompleted) {
        scoreA = '$runs/$wkts ($ov ov)';
      }
    } else if (isCounty && m.liveScore != null && (m.liveScore!['runs'] != null || isCompleted)) {
      final runs = m.liveScore!['runs'] ?? 0;
      final wkts = m.liveScore!['wickets'] ?? 0;
      final ov = m.liveScore!['overs'] ?? '0.0';
      scoreA = '$runs/$wkts ($ov ov)';
    }

    if (!isCounty) {
      if (teamBInn != null && (teamBInn.legalBalls > 0 || teamBInn.runs > 0 || isCompleted)) {
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
        resultText = '$winnerName won by $remWickets ${remWickets == 1 ? 'wicket' : 'wickets'}';
      } else if (i1.runs > i2.runs) {
        final remRuns = i1.runs - i2.runs;
        final winnerName = teamAInn == i1 ? m.teamA : m.teamB;
        resultText = '$winnerName won by $remRuns ${remRuns == 1 ? 'run' : 'runs'}';
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
    } else if (isLive && !isCounty && i1 != null && i1.isComplete && i2 != null && !i2.isComplete) {
      final target = i1.runs + 1;
      final needed = target - i2.runs;
      final remBalls = (m.totalOvers * 6) - i2.legalBalls;
      final chasingTeam = teamBInn == i2 ? m.teamB : m.teamA;
      if (needed > 0 && remBalls >= 0) {
        resultText = '$chasingTeam need $needed runs in $remBalls balls';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isLive ? 3 : 1,
      shadowColor: isLive ? const Color(0xFFEF4444).withOpacity(0.25) : Colors.black.withOpacity(0.06),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLive ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isLive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (m.tournamentId.isNotEmpty) {
            if (m.status == MatchStatus.completed) {
              context.push('/tournaments/${m.tournamentId}/matches/${m.id}/summary');
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
              // ── Header Row: Badge & Date ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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
                        if (isLive) ...[
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else if (isCompleted) ...[
                          const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isLive ? 'LIVE' : (isCompleted ? 'COMPLETED' : m.status.label.toUpperCase()),
                          style: TextStyle(
                            color: isLive
                                ? const Color(0xFFDC2626)
                                : isCompleted
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(m.matchDate),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Team A Row ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      m.teamA.isNotEmpty ? m.teamA.substring(0, 1).toUpperCase() : 'A',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E3A8A)),
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

              // ── Team B Row ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isCounty ? const Color(0xFFFEF3C7) : const Color(0xFFFDF2F8),
                    child: Text(
                      m.teamB.isNotEmpty ? m.teamB.substring(0, 1).toUpperCase() : 'B',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: isCounty ? const Color(0xFFB45309) : const Color(0xFF9D174D),
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

              // ── Result Banner (Trophy / Highlight) ──
              if (resultText != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
                        size: 14,
                        color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          resultText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCompleted ? const Color(0xFF15803D) : const Color(0xFF475569),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Footer: Venue, Overs & Chevron ──
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${m.venue.isNotEmpty ? m.venue : 'Ground'} • ${isCounty ? 'County' : '${m.totalOvers} Overs'}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
