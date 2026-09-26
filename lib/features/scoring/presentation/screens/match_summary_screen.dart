import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../matches/data/models/match.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../data/models/innings.dart';
import '../providers/scoring_providers.dart';
import 'scorecard_tab.dart';

class MatchSummaryScreen extends ConsumerStatefulWidget {
  const MatchSummaryScreen({super.key, required this.tournamentId, required this.matchId});
  final String tournamentId;
  final String matchId;

  @override
  ConsumerState<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends ConsumerState<MatchSummaryScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabCount = 0;

  void _initTabController(int count) {
    if (_tabController != null && _currentTabCount == count) return;
    _tabController?.dispose();
    _currentTabCount = count;
    _tabController = TabController(length: count, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    )));
    final i1Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1)));
    final i2Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2)));

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
        title: const Text(
          'Match Center',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 0.3),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              ref.refresh(matchDetailProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));
              ref.refresh(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1)));
              ref.refresh(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2)));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: matchAsync.when(
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
                Text('Error loading match: $e', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        data: (match) {
          if (match == null) {
            return const Center(child: Text('Match not found', style: TextStyle(fontWeight: FontWeight.bold)));
          }

          final i1 = i1Async.value;
          final i2 = i2Async.value;
          final isCounty = match.liveScore?['matchType'] == 'county' || match.liveScore?['isCounty'] == true;

          final tabCount = isCounty ? 2 : 3;
          _initTabController(tabCount);

          final resultText = _getMatchResult(match, i1, i2, isCounty);
          final isCompleted = match.isCompleted || (isCounty && i1 != null && i1.isComplete) || (i2 != null && i2.isComplete);

          return Column(
            children: [
              // ── 1. PREMIUM HEADER HERO SCOREBOARD ──
              _buildHeaderHero(context, match, i1, i2, isCounty, resultText, isCompleted),

              // ── 2. STYLED PINNED TAB BAR ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                    tabs: isCounty
                        ? const [
                            Tab(text: 'MATCH INFO'),
                            Tab(text: 'SCORECARD'),
                          ]
                        : [
                            const Tab(text: 'MATCH INFO'),
                            Tab(text: '1ST INN (${match.teamAShort})'),
                            Tab(text: '2ND INN (${match.teamBShort})'),
                          ],
                  ),
                ),
              ),

              // ── 3. TAB VIEWS ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: isCounty
                      ? [
                          _InfoTab(match: match, i1: i1, i2: i2, isCounty: true),
                          i1 != null
                              ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i1)
                              : const Center(child: Text('Scorecard not available yet', style: TextStyle(fontWeight: FontWeight.bold))),
                        ]
                      : [
                          _InfoTab(match: match, i1: i1, i2: i2, isCounty: false),
                          i1 != null
                              ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i1)
                              : const Center(child: Text('1st Innings has not started yet', style: TextStyle(fontWeight: FontWeight.bold))),
                          i2 != null
                              ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i2)
                              : const Center(child: Text('2nd Innings has not started yet', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER HERO SCOREBOARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderHero(
    BuildContext context,
    MatchModel match,
    Innings? i1,
    Innings? i2,
    bool isCounty,
    String resultText,
    bool isCompleted,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Match Venue & Type Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${match.venue.isNotEmpty ? match.venue : 'Ground'} • ${DateFormat('MMM dd, yyyy').format(match.matchDate)}',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCounty ? const Color(0xFFF59E0B).withOpacity(0.2) : const Color(0xFF38BDF8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCounty ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8), width: 0.8),
                ),
                child: Text(
                  isCounty ? 'COUNTY' : '${match.totalOvers} OVERS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isCounty ? const Color(0xFFFDE68A) : const Color(0xFFBAE6FD),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Team A vs Team B Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A Card
              Expanded(
                child: _buildTeamScoreBox(
                  teamName: match.teamA,
                  teamId: match.teamAId,
                  i1: i1,
                  i2: i2,
                  isCounty: isCounty,
                  isTeamA: true,
                ),
              ),

              // VS separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ),

              // Team B Card
              Expanded(
                child: _buildTeamScoreBox(
                  teamName: match.teamB,
                  teamId: match.teamBId,
                  i1: i1,
                  i2: i2,
                  isCounty: isCounty,
                  isTeamA: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Result / Status Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              gradient: isCompleted
                  ? const LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF047857)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : (match.isLive
                      ? const LinearGradient(
                          colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF334155)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF34D399).withOpacity(0.4)
                    : (match.isLive ? const Color(0xFFF87171).withOpacity(0.4) : const Color(0xFF64748B).withOpacity(0.4)),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted
                      ? Icons.emoji_events_rounded
                      : (match.isLive ? Icons.radio_button_checked_rounded : Icons.schedule_rounded),
                  color: isCompleted ? const Color(0xFFFDE68A) : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    resultText,
                    style: TextStyle(
                      color: isCompleted ? const Color(0xFFFDE68A) : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreBox({
    required String teamName,
    required String teamId,
    required Innings? i1,
    required Innings? i2,
    required bool isCounty,
    required bool isTeamA,
  }) {
    Innings? teamInn;
    if (i1?.battingTeamId == teamId) teamInn = i1;
    if (i2?.battingTeamId == teamId) teamInn = i2;

    // For county matches, team A is the single batting team if not mapped
    if (isCounty && teamInn == null && isTeamA && i1 != null) {
      teamInn = i1;
    }

    final hasBat = teamInn != null && (teamInn.legalBalls > 0 || teamInn.runs > 0);
    final crr = (teamInn != null && teamInn.legalBalls > 0)
        ? (teamInn.runs / (teamInn.legalBalls / 6)).toStringAsFixed(2)
        : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          // Team Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isTeamA ? const Color(0xFF38BDF8).withOpacity(0.2) : const Color(0xFFF472B6).withOpacity(0.2),
            child: Text(
              teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : 'T',
              style: TextStyle(
                color: isTeamA ? const Color(0xFF7DD3FC) : const Color(0xFFF9A8D4),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Team Name
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Score / Status
          if (hasBat) ...[
            Text(
              '${teamInn!.runs}/${teamInn.wickets}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              '(${teamInn.oversText} ov)',
              style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, fontSize: 11),
            ),
            if (crr != null)
              Text(
                'CRR: $crr',
                style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 9.5),
              ),
          ] else if (isCounty && !isTeamA) ...[
            const Text(
              'Opponent',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ] else if (match.isCompleted) ...[
            const Text(
              '—',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            const Text(
              'Yet to bat',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPREHENSIVE MATCH RESULT CALCULATION
  // ─────────────────────────────────────────────────────────────────────────
  String _getMatchResult(MatchModel match, Innings? i1, Innings? i2, bool isCounty) {
    // 1. Check direct result text from database
    if (match.resultText != null && match.resultText!.trim().isNotEmpty) {
      return match.resultText!;
    }
    final liveResult = match.liveScore?['result']?.toString() ?? match.liveScore?['resultText']?.toString();
    if (liveResult != null && liveResult.trim().isNotEmpty) {
      return liveResult;
    }

    // 2. County Duel Match (1 Innings)
    if (isCounty) {
      if (match.isCompleted || (i1 != null && i1.isComplete)) {
        final runs = i1?.runs ?? 0;
        final wkts = i1?.wickets ?? 0;
        final overs = i1?.oversText ?? '0.0';
        return '${match.teamA} scored $runs/$wkts ($overs ov) • Match Completed';
      }
      return 'County Match in progress...';
    }

    // 3. Normal 2-Innings Match
    if (i1 != null && i2 != null && (i2.isComplete || match.isCompleted)) {
      final i1Team = i1.battingTeamId == match.teamAId ? match.teamA : match.teamB;
      final i2Team = i2.battingTeamId == match.teamAId ? match.teamA : match.teamB;

      if (i2.runs > i1.runs) {
        final remWickets = 10 - i2.wickets;
        return '$i2Team won by $remWickets ${remWickets == 1 ? 'wicket' : 'wickets'}';
      } else if (i1.runs > i2.runs) {
        final remRuns = i1.runs - i2.runs;
        return '$i1Team won by $remRuns ${remRuns == 1 ? 'run' : 'runs'}';
      } else {
        return 'Match Tied (${i1.runs} runs each)';
      }
    }

    // 4. Completed match fallback
    if (match.isCompleted) {
      if (match.winnerTeamId != null) {
        final winnerName = match.teamNameById(match.winnerTeamId);
        return '$winnerName won the match';
      }
      if (i1 != null) {
        return 'Match Completed • ${match.teamA} scored ${i1.runs}/${i1.wickets}';
      }
      return 'Match Completed';
    }

    // 5. Live match chasing target
    if (i1 != null && i1.isComplete && i2 != null && !i2.isComplete) {
      final target = i1.runs + 1;
      final needed = target - i2.runs;
      final remBalls = (match.totalOvers * 6) - i2.legalBalls;
      final chasingTeam = i2.battingTeamId == match.teamAId ? match.teamA : match.teamB;
      if (needed <= 0) {
        return '$chasingTeam won the match';
      }
      return '$chasingTeam need $needed runs in $remBalls balls';
    }

    if (i1 != null && !i1.isComplete) {
      final battingTeam = match.teamNameById(i1.battingTeamId);
      return '1st Innings: $battingTeam batting (${i1.runs}/${i1.wickets})';
    }

    return 'Match Scheduled';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENHANCED INFO TAB
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.match,
    this.i1,
    this.i2,
    required this.isCounty,
  });

  final MatchModel match;
  final Innings? i1;
  final Innings? i2;
  final bool isCounty;

  @override
  Widget build(BuildContext context) {
    final tossWinner = match.tossWinnerId == match.teamAId ? match.teamA : match.teamB;
    final tossDecisionStr = match.tossDecision?.name.toUpperCase() ?? 'BAT';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // ── MATCH DETAILS CARD ──
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF1E3A8A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'MATCH INFORMATION',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                _infoRow(Icons.sports_cricket_rounded, 'Match', '${match.teamA} vs ${match.teamB}'),
                _infoRow(
                  Icons.category_rounded,
                  'Match Format',
                  isCounty ? 'County Single-Innings Duel' : 'Limited Overs (${match.totalOvers} Overs)',
                ),
                _infoRow(
                  Icons.calendar_month_rounded,
                  'Date & Time',
                  DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(match.matchDate),
                ),
                if (match.hasToss)
                  _infoRow(
                    Icons.toll_rounded,
                    'Toss',
                    '$tossWinner won toss & elected to $tossDecisionStr',
                    highlight: true,
                  ),
                _infoRow(Icons.stadium_rounded, 'Venue', match.venue.isNotEmpty ? match.venue : 'Cricket Ground'),
                _infoRow(Icons.timer_rounded, 'Total Overs', '${match.totalOvers} Overs per side'),
                _infoRow(
                  Icons.flag_rounded,
                  'Match Status',
                  match.status.name.toUpperCase(),
                  statusColor: match.isCompleted
                      ? const Color(0xFF059669)
                      : (match.isLive ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        ),

        // ── INNINGS SUMMARY CARD ──
        if (i1 != null) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.analytics_outlined, color: Color(0xFF1E3A8A), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'INNINGS BREAKDOWN',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 12.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _inningsSummaryRow(
                    label: isCounty ? 'County Innings' : '1st Innings (${match.teamA})',
                    inn: i1!,
                  ),
                  if (i2 != null) ...[
                    const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    _inningsSummaryRow(
                      label: '2nd Innings (${match.teamB})',
                      inn: i2!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _inningsSummaryRow({required String label, required Innings inn}) {
    final crr = inn.legalBalls > 0 ? (inn.runs / (inn.legalBalls / 6)).toStringAsFixed(2) : '0.00';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text('CRR: $crr • Extras: ${inn.extras}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Text(
            '${inn.runs}/${inn.wickets} (${inn.oversText})',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF1E3A8A)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: statusColor ?? (highlight ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
