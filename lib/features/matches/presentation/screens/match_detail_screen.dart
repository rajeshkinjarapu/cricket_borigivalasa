import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../../../scoring/data/models/innings.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  final String tournamentId;
  final String matchId;

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  String? _selectedTossWinner;
  TossDecision? _selectedDecision;
  bool _isSavingToss = false;
  bool _isDeleting = false;

  ImageProvider? _getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      if (url.startsWith('data:image') || url.length > 500) {
        final base64String = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(url);
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordToss(Match match) async {
    if (_selectedTossWinner == null || _selectedDecision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select who won the toss and their decision.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSavingToss = true);
    try {
      await ref.read(matchRepositoryProvider).setToss(
            tournamentId: widget.tournamentId,
            matchId: widget.matchId,
            tossWinnerTeamId: _selectedTossWinner!,
            tossDecision: _selectedDecision!,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toss recorded successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving toss: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingToss = false);
    }
  }

  Future<void> _deleteMatch(Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 10),
            Text('Delete Match', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the match between "${match.teamA}" and "${match.teamB}"?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete Match', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(matchRepositoryProvider).delete(widget.tournamentId, widget.matchId);
      if (mounted) {
        ref.invalidate(tournamentMatchesProvider(widget.tournamentId));
        ref.invalidate(matchListProvider(widget.tournamentId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match deleted successfully!'), backgroundColor: Color(0xFF16A34A)),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/tournaments/${widget.tournamentId}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting match: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    )));

    final currentUser = ref.watch(currentUserProvider);
    final canScore = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.scorer;
    final isAdmin = currentUser?.role == UserRole.admin;

    return matchAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: const Text('Match Error'),
        ),
        body: Center(child: Text('Error loading match: $e')),
      ),
      data: (match) {
        if (match == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              title: const Text('Match Not Found'),
            ),
            body: const Center(
              child: Text(
                'Match not found or has been deleted.',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        final teamAAsync = ref.watch(teamDetailProvider(match.teamAId));
        final teamBAsync = ref.watch(teamDetailProvider(match.teamBId));
        final teamA = teamAAsync.value;
        final teamB = teamBAsync.value;

        final teamAPlayersAsync = ref.watch(teamPlayersProvider(match.teamAId));
        final teamBPlayersAsync = ref.watch(teamPlayersProvider(match.teamBId));
        final teamAPlayers = teamAPlayersAsync.value ?? [];
        final teamBPlayers = teamBPlayersAsync.value ?? [];

        final i1Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1)));
        final i2Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2)));
        final inn1 = i1Async.value;
        final inn2 = i2Async.value;

        final isCounty = match.liveScore?['matchType'] == 'county' || match.liveScore?['isCounty'] == true;
        final isTossDone = match.hasToss || isCounty;
        final tossWinnerName = match.tossWinnerId == match.teamAId ? match.teamA : match.teamB;
        final battingFirstTeam = match.tossDecision == TossDecision.bat
            ? (match.tossWinnerId == match.teamAId ? match.teamA : match.teamB)
            : (match.tossWinnerId == match.teamAId ? match.teamB : match.teamA);

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
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
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
            title: Text(
              isCounty ? 'County Duel' : 'Match Details',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 0.3),
            ),
            actions: [
              if (isAdmin) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Edit Match',
                  onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/edit'),
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/edit');
                    } else if (val == 'delete') {
                      _deleteMatch(match);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 10),
                          Text('Edit Match Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever_rounded, size: 20, color: Color(0xFFDC2626)),
                          SizedBox(width: 10),
                          Text('Delete Match', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          body: _isDeleting
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFDC2626)),
                      SizedBox(height: 16),
                      Text('Deleting match...', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. STUNNING CRICHEROES HERO CARD ──
                      _buildHeroCard(
                        context,
                        match,
                        teamA,
                        teamB,
                        teamAPlayers.length,
                        teamBPlayers.length,
                        isCounty,
                        inn1,
                        inn2,
                      ),
                      const SizedBox(height: 16),

                      // ── 2. MATCH STATUS / ACTIONS SECTION ──
                      if (match.status == MatchStatus.completed) ...[
                        _buildCompletedCard(context, match, isCounty),
                        const SizedBox(height: 16),
                      ] else if (match.status == MatchStatus.live) ...[
                        _buildLiveActionsCard(context, match, canScore),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Scheduled match
                        if (!isTossDone && canScore) ...[
                          _buildTossSetupCard(context, match),
                          const SizedBox(height: 16),
                        ],
                        if (isTossDone) ...[
                          _buildTossRecordedCard(context, match, tossWinnerName, battingFirstTeam, isCounty),
                          const SizedBox(height: 16),
                          _buildStartMatchButton(context, match, teamA, teamB, teamAPlayers, teamBPlayers, isCounty),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // ── 3. MATCH OVERVIEW GRID (CRICHEROES STYLE) ──
                      _buildOverviewGrid(match, isCounty),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. HERO CARD (STADIUM VIBES WITH DYNAMIC SCORES & WINNER BADGE)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(
    BuildContext context,
    Match match,
    Team? teamA,
    Team? teamB,
    int countA,
    int countB,
    bool isCounty,
    Innings? inn1,
    Innings? inn2,
  ) {
    final imageProviderA = _getImageProvider(teamA?.logoUrl);
    final imageProviderB = _getImageProvider(teamB?.logoUrl);

    final targetRuns = match.liveScore?['targetRuns'];
    final totalBalls = match.liveScore?['totalBalls'];

    // Resolve score strings if available
    String formatInningsScore(Innings? inn) {
      if (inn == null) return '';
      final overs = inn.legalBalls ~/ 6;
      final balls = inn.legalBalls % 6;
      final ovStr = balls == 0 ? '$overs' : '$overs.$balls';
      return '${inn.runs}/${inn.wickets} ($ovStr ov)';
    }

    String scoreA = '';
    String scoreB = '';

    if (inn1 != null) {
      if (inn1.battingTeamId == match.teamAId || isCounty) {
        scoreA = formatInningsScore(inn1);
      } else if (inn1.battingTeamId == match.teamBId) {
        scoreB = formatInningsScore(inn1);
      }
    }
    if (inn2 != null) {
      if (inn2.battingTeamId == match.teamAId) {
        scoreA = formatInningsScore(inn2);
      } else if (inn2.battingTeamId == match.teamBId) {
        scoreB = formatInningsScore(inn2);
      }
    }

    // Check winner
    final winnerId = match.winnerTeamId;
    final isWinnerA = match.status == MatchStatus.completed && winnerId != null && winnerId == match.teamAId;
    final isWinnerB = match.status == MatchStatus.completed && winnerId != null && winnerId == match.teamBId;

    return Column(
      children: [
        // ── TOP STATUS & FORMAT BADGES ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: match.status == MatchStatus.live
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : match.status == MatchStatus.completed
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (match.status == MatchStatus.live) ...[
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    ),
                  ] else if (match.status == MatchStatus.completed) ...[
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    match.status.label.toUpperCase(),
                    style: TextStyle(
                      color: match.status == MatchStatus.live
                          ? const Color(0xFFDC2626)
                          : match.status == MatchStatus.completed
                              ? const Color(0xFF059669)
                              : const Color(0xFF2563EB),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isCounty ? Icons.bolt_rounded : Icons.sports_cricket_rounded, color: const Color(0xFF64748B), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    isCounty ? 'COUNTY DUEL' : 'TOURNAMENT MATCH',
                    style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── COUNTY TARGET GLOWING BANNER ──
        if (isCounty && targetRuns != null && totalBalls != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.track_changes_rounded, color: Color(0xFFD97706), size: 14),
                const SizedBox(width: 6),
                Text(
                  'TARGET: $targetRuns RUNS IN $totalBalls BALLS',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ── PLAYERS / TEAMS FACE-OFF SECTION ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── PLAYER / TEAM A ──
            Expanded(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isWinnerA ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                            width: isWinnerA ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isWinnerA ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: imageProviderA != null ? DecorationImage(image: imageProviderA, fit: BoxFit.cover) : null,
                        ),
                        alignment: Alignment.center,
                        child: imageProviderA == null
                            ? Text(
                                teamA?.shortName ?? match.teamA.substring(0, (match.teamA.length >= 2 ? 2 : 1)).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  fontSize: 22,
                                ),
                              )
                            : null,
                      ),
                      if (isWinnerA)
                        Positioned(
                          top: -12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.4), blurRadius: 6)],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👑', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text('WIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    match.teamA,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  if (scoreA.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        scoreA,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── CENTER VS EMBLEM ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),

            // ── PLAYER / TEAM B ──
            Expanded(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isWinnerB ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                            width: isWinnerB ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isWinnerB ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: imageProviderB != null ? DecorationImage(image: imageProviderB, fit: BoxFit.cover) : null,
                        ),
                        alignment: Alignment.center,
                        child: imageProviderB == null
                            ? Text(
                                teamB?.shortName ?? match.teamB.substring(0, (match.teamB.length >= 2 ? 2 : 1)).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  fontSize: 22,
                                ),
                              )
                            : null,
                      ),
                      if (isWinnerB)
                        Positioned(
                          top: -12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.4), blurRadius: 6)],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👑', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text('WIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    match.teamB,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  if (scoreB.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        scoreB,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── VENUE & TIME (BEAUTIFUL SMALL BOXES) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, color: Color(0xFF64748B), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    match.venue.isNotEmpty ? match.venue : 'Cricket Ground',
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse_rounded, color: Color(0xFF64748B), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${match.totalOvers} Overs',
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM').format(match.matchDate),
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. COMPLETED MATCH RESULT & QUICK ACTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCompletedCard(BuildContext context, Match match, bool isCounty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFFD97706).withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MATCH RESULT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB45309),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match.resultText ?? 'Match Completed',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/summary'),
                  icon: const Icon(Icons.sports_score_rounded, size: 20, color: Colors.white),
                  label: const Text('MATCH SUMMARY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/charts'),
                  icon: const Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF1E3A8A)),
                  label: const Text('CHARTS & STATS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E3A8A))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. LIVE MATCH CONTROLS & STREAM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLiveActionsCard(BuildContext context, Match match, bool canScore) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE MATCH IN PROGRESS',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (canScore) ...[
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring'),
              icon: const Icon(Icons.edit_note_rounded, size: 22, color: Colors.white),
              label: const Text(
                'OPEN LIVE SCORER CONSOLE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                shadowColor: const Color(0xFFEA580C).withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/live'),
            icon: const Icon(Icons.stream_rounded, size: 20, color: Colors.white),
            label: const Text(
              'WATCH LIVE SCORES & STREAM',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ── START MATCH / SQUADS BUTTON ──
  Widget _buildStartMatchButton(
    BuildContext context,
    Match match,
    Team? teamA,
    Team? teamB,
    List teamAPlayers,
    List teamBPlayers,
    bool isCounty,
  ) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (isCounty) {
            if (match.status != MatchStatus.live) {
              final scoringRepo = ref.read(scoringRepositoryProvider);
              final batTeam = teamA;
              final bowlTeam = teamB;
              final striker = teamAPlayers.isNotEmpty ? teamAPlayers.first : null;
              final bowler = teamBPlayers.isNotEmpty ? teamBPlayers.first : null;

              if (batTeam != null && bowlTeam != null && striker != null && bowler != null) {
                await scoringRepo.initInnings(
                  tournamentId: widget.tournamentId,
                  matchId: widget.matchId,
                  inningsNumber: 1,
                  battingTeam: batTeam,
                  bowlingTeam: bowlTeam,
                  openingStriker: striker,
                  openingNonStriker: null,
                  openingBowler: bowler,
                );
              } else {
                final controller = ref.read(matchControllerProvider.notifier);
                await controller.update(match.copyWith(status: MatchStatus.live));
              }
            }
            if (mounted) {
              context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring');
            }
          } else {
            context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/squads');
          }
        },
        icon: const Icon(Icons.sports_cricket_rounded, size: 22, color: Colors.white),
        label: Text(
          isCounty ? 'START COUNTY DUEL (SCOREBOARD)' : 'SELECT SQUADS & START MATCH',
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          shadowColor: const Color(0xFF16A34A).withOpacity(0.4),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. OVERVIEW GRID (CRICHEROES MODERN TILES)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewGrid(Match match, bool isCounty) {
    return const SizedBox.shrink();
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return const SizedBox.shrink();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. TOSS SETUP & RECORDED CARDS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTossRecordedCard(
    BuildContext context,
    Match match,
    String tossWinner,
    String battingFirst,
    bool isCounty,
  ) {
    if (isCounty) {
      final targetRuns = match.liveScore?['targetRuns'] ?? 30;
      final totalBalls = match.liveScore?['totalBalls'] ?? 12;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD97706).withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'County Challenge Set',
                  style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${match.teamA} is batting to chase $targetRuns runs in $totalBalls balls.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 3),
            Text(
              '${match.teamB} is bowling to defend the target.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFDCFCE7),
            const Color(0xFFBBF7D0).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              children: [
                Text(
                  '$tossWinner won the toss\nand elected to ${match.tossDecision?.label.toLowerCase() ?? 'bat'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF14532D),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_cricket, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text(
                        '$battingFirst will bat first',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -24,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTossSetupCard(BuildContext context, Match match) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.how_to_vote_rounded, color: Color(0xFF1E3A8A), size: 20),
              SizedBox(width: 8),
              Text(
                'Toss Setup',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Who won the toss?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  match.teamA,
                  _selectedTossWinner == match.teamAId,
                  () => setState(() => _selectedTossWinner = match.teamAId),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceChip(
                  match.teamB,
                  _selectedTossWinner == match.teamBId,
                  () => setState(() => _selectedTossWinner = match.teamBId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Elected to?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  'Bat First',
                  _selectedDecision == TossDecision.bat,
                  () => setState(() => _selectedDecision = TossDecision.bat),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceChip(
                  'Bowl First',
                  _selectedDecision == TossDecision.bowl,
                  () => setState(() => _selectedDecision = TossDecision.bowl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSavingToss ? null : () => _recordToss(match),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSavingToss
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CONFIRM TOSS DECISION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13.5,
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
