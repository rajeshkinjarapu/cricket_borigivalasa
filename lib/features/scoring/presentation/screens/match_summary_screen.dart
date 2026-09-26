import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../matches/data/models/match.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
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
    final allPlayers = ref.watch(allPlayersProvider).value ?? [];
    final allTeams = ref.watch(allTeamsProvider).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
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
              // ── 1. PREMIUM HERO SCOREBOARD WITH AVATARS ──
              _buildHeaderHero(context, match, i1, i2, isCounty, resultText, isCompleted, allPlayers, allTeams),

              // ── 2. STYLED PINNED TAB BAR ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.4),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                    tabs: isCounty
                        ? const [
                            Tab(text: 'MATCH INFO'),
                            Tab(text: 'SCORECARD'),
                          ]
                        : [
                            const Tab(text: 'MATCH INFO'),
                            Tab(text: '1ST INN'),
                            Tab(text: '2ND INN'),
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
                              ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i1, match: match)
                              : const Center(child: Text('Scorecard not available yet', style: TextStyle(fontWeight: FontWeight.bold))),
                        ]
                      : [
                          _InfoTab(match: match, i1: i1, i2: i2, isCounty: false),
                          i1 != null
                              ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i1, match: match)
                              : const Center(child: Text('1st Innings has not started yet', style: TextStyle(fontWeight: FontWeight.bold))),
                          i2 != null
                              ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i2, match: match)
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
  // PREMIUM & BEAUTIFUL HERO SCOREBOARD WITH PLAYER AVATARS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderHero(
    BuildContext context,
    MatchModel match,
    Innings? i1,
    Innings? i2,
    bool isCounty,
    String resultText,
    bool isCompleted,
    List<Player> allPlayers,
    List<Team> allTeams,
  ) {
    // Determine team 1 & 2 innings
    Innings? innA;
    Innings? innB;
    if (i1?.battingTeamId == match.teamAId) innA = i1;
    if (i2?.battingTeamId == match.teamAId) innA = i2;
    if (i1?.battingTeamId == match.teamBId) innB = i1;
    if (i2?.battingTeamId == match.teamBId) innB = i2;

    if (isCounty && innA == null && i1 != null) {
      innA = i1;
    }

    String? photoA = _findPhoto(match.teamAId, match.teamA, allPlayers, allTeams);
    String? photoB = _findPhoto(match.teamBId, match.teamB, allPlayers, allTeams);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Meta Bar ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${match.venue.isNotEmpty ? match.venue : 'Cricket Ground'} • ${DateFormat('MMM dd, yyyy').format(match.matchDate)}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isCounty ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isCounty ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE), width: 1),
                ),
                child: Text(
                  isCounty ? 'COUNTY' : '${match.totalOvers} OVERS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isCounty ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Integrated Scoreboard Card with Player Photos ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              children: [
                // Team A Row
                _buildTeamRow(
                  name: match.teamA,
                  photoUrl: photoA,
                  inn: innA,
                  isCounty: isCounty,
                  isBattingNow: i1 != null && !i1.isComplete && i1.battingTeamId == match.teamAId,
                  isWinner: match.winnerTeamId == match.teamAId,
                  isCompleted: isCompleted,
                  isPrimary: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                // Team B Row
                _buildTeamRow(
                  name: match.teamB,
                  photoUrl: photoB,
                  inn: innB,
                  isCounty: isCounty,
                  isBattingNow: i2 != null && !i2.isComplete && i2.battingTeamId == match.teamBId,
                  isWinner: match.winnerTeamId == match.teamBId,
                  isCompleted: isCompleted,
                  isOpponentInCounty: isCounty,
                  isPrimary: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Result / Status Pill ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFECFDF5)
                  : (match.isLive ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFFA7F3D0)
                    : (match.isLive ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted
                      ? Icons.emoji_events_rounded
                      : (match.isLive ? Icons.radio_button_checked_rounded : Icons.info_outline_rounded),
                  color: isCompleted
                      ? const Color(0xFF059669)
                      : (match.isLive ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    resultText,
                    style: TextStyle(
                      color: isCompleted
                          ? const Color(0xFF065F46)
                          : (match.isLive ? const Color(0xFF991B1B) : const Color(0xFF334155)),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    maxLines: 1,
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

  String? _findPhoto(String id, String name, List<Player> players, List<Team> teams) {
    // 1. By ID in players
    final pById = players.where((p) => p.id == id).firstOrNull;
    if (pById?.profilePicUrl != null && pById!.profilePicUrl!.isNotEmpty) return pById.profilePicUrl;

    // 2. By Name in players
    final trimmed = name.trim().toLowerCase();
    final pByName = players.where((p) => p.name.trim().toLowerCase() == trimmed).firstOrNull;
    if (pByName?.profilePicUrl != null && pByName!.profilePicUrl!.isNotEmpty) return pByName.profilePicUrl;

    // 3. By Team Logo
    final tById = teams.where((t) => t.id == id).firstOrNull;
    if (tById?.logoUrl != null && tById!.logoUrl!.isNotEmpty) return tById.logoUrl;

    final tByName = teams.where((t) => t.name.trim().toLowerCase() == trimmed).firstOrNull;
    if (tByName?.logoUrl != null && tByName!.logoUrl!.isNotEmpty) return tByName.logoUrl;

    return null;
  }

  Widget _buildTeamRow({
    required String name,
    required String? photoUrl,
    required Innings? inn,
    required bool isCounty,
    required bool isBattingNow,
    required bool isWinner,
    required bool isCompleted,
    required bool isPrimary,
    bool isOpponentInCounty = false,
  }) {
    final hasBat = inn != null && (inn.legalBalls > 0 || inn.runs > 0);
    final crr = (inn != null && inn.legalBalls > 0)
        ? (inn.runs / (inn.legalBalls / 6)).toStringAsFixed(2)
        : null;

    return Row(
      children: [
        // ── Person / Team Avatar ──
        CircleAvatar(
          radius: 16,
          backgroundColor: isPrimary ? const Color(0xFFDBEAFE) : const Color(0xFFFCE7F3),
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
          child: (photoUrl == null || photoUrl.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isPrimary ? const Color(0xFF1D4ED8) : const Color(0xFFBE185D),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),

        // ── Name & Winner / Live Badge ──
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isWinner ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    fontWeight: isWinner ? FontWeight.w900 : FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isWinner) ...[
                const SizedBox(width: 5),
                const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF059669)),
              ],
              if (isBattingNow) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BAT',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Score display ──
        if (hasBat) ...[
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${inn!.runs}/${inn.wickets}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text: ' (${inn.oversText})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (crr != null)
                  TextSpan(
                    text: '  CRR $crr',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      color: Color(0xFF2563EB),
                    ),
                  ),
              ],
            ),
          ),
        ] else if (isOpponentInCounty) ...[
          const Text(
            'Opponent',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ] else if (isCompleted) ...[
          const Text(
            '—',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ] else ...[
          const Text(
            'Yet to bat',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ],
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
      if (match.winnerTeamId != null && match.winnerTeamId!.isNotEmpty) {
        final winnerName = match.teamNameById(match.winnerTeamId);
        return '$winnerName won';
      }
      if (match.isCompleted || (i1 != null && i1.isComplete)) {
        return 'Match Completed';
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
        return 'Match Tied';
      }
    }

    // 4. Completed match fallback
    if (match.isCompleted) {
      if (match.winnerTeamId != null && match.winnerTeamId!.isNotEmpty) {
        final winnerName = match.teamNameById(match.winnerTeamId);
        return '$winnerName won';
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
// ENHANCED & COMPACT INFO TAB
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // ── MATCH DETAILS CARD ──
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF1E3A8A), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'MATCH INFORMATION',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontSize: 11.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14, color: Color(0xFFE2E8F0)),
                _infoRow(Icons.sports_cricket_rounded, 'Match', '${match.teamA} vs ${match.teamB}'),
                _infoRow(
                  Icons.category_rounded,
                  'Format',
                  isCounty ? 'County Single-Innings Duel' : 'Limited Overs (${match.totalOvers} Overs)',
                ),
                _infoRow(
                  Icons.calendar_month_rounded,
                  'Date & Time',
                  DateFormat('EEE, MMM dd, yyyy • hh:mm a').format(match.matchDate),
                ),
                if (match.hasToss)
                  _infoRow(
                    Icons.toll_rounded,
                    'Toss',
                    '$tossWinner won toss & elected to $tossDecisionStr',
                    highlight: true,
                  ),
                _infoRow(Icons.stadium_rounded, 'Venue', match.venue.isNotEmpty ? match.venue : 'Cricket Ground'),
                _infoRow(Icons.timer_rounded, 'Overs', '${match.totalOvers} Overs per side'),
                _infoRow(
                  Icons.flag_rounded,
                  'Status',
                  match.status.name.toUpperCase(),
                  statusColor: match.isCompleted
                      ? const Color(0xFF059669)
                      : (match.isLive ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        ),

        // ── INNINGS SUMMARY CARD (For non-county or detailed breakdown) ──
        if (!isCounty && i1 != null) ...[
          const SizedBox(height: 8),
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.analytics_outlined, color: Color(0xFF1E3A8A), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'INNINGS BREAKDOWN',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  _inningsSummaryRow(
                    label: '1st Innings (${match.teamA})',
                    inn: i1!,
                  ),
                  if (i2 != null) ...[
                    const Divider(height: 12, color: Color(0xFFF1F5F9)),
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A))),
            const SizedBox(height: 1),
            Text('CRR: $crr • Extras: ${inn.extras}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Text(
            '${inn.runs}/${inn.wickets} (${inn.oversText})',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF1E3A8A)),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 12.5, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: statusColor ?? (highlight ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
