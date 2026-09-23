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
        // Manually invalidate the providers to force a re-fetch since Supabase realtime doesn't broadcast deletions by default
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

        final isCounty = match.liveScore?['matchType'] == 'county' || match.liveScore?['isCounty'] == true;
        final isTossDone = match.hasToss || isCounty; // In County, batsman always bats first
        final tossWinnerName = match.tossWinnerId == match.teamAId ? match.teamA : match.teamB;
        final battingFirstTeam = match.tossDecision == TossDecision.bat
            ? (match.tossWinnerId == match.teamAId ? match.teamA : match.teamB)
            : (match.tossWinnerId == match.teamAId ? match.teamB : match.teamA);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF065F46)],
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
                  color: Colors.white.withOpacity(0.15),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCounty ? 'County Duel Dashboard' : 'Match Dashboard',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                ),
                Text(
                  isCounty ? '⚡ Target Chase Contest' : 'Match Overview & Live Status',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF93C5FD)),
                ),
              ],
            ),
            actions: [
              if (isAdmin) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
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
                      color: Colors.white.withOpacity(0.15),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. COLORFUL STADIUM VS HERO CARD ──
                      _buildVsHeroCard(
                        context,
                        match,
                        teamA,
                        teamB,
                        teamAPlayers.length,
                        teamBPlayers.length,
                        isCounty,
                      ),
                      const SizedBox(height: 16),

                      // ── 2. TOSS / COUNTY CHALLENGE STATUS CARD ──
                      if (match.status == MatchStatus.scheduled) ...[
                        if (!isTossDone && canScore) ...[
                          _buildTossSetupCard(context, match),
                          const SizedBox(height: 16),
                        ],
                        if (isTossDone) ...[
                          _buildTossRecordedCard(context, match, tossWinnerName, battingFirstTeam, isCounty),
                          const SizedBox(height: 16),

                          // ── GREEN PROMINENT SQUADS / SCORING BUTTON ──
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (isCounty) {
                                  if (match.status != MatchStatus.live) {
                                    final scoringRepo = ref.read(scoringRepositoryProvider);
                                    
                                    // Extract the correct teams and players
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
                                        openingNonStriker: null, // No non-striker for county
                                        openingBowler: bowler,
                                      );
                                    } else {
                                      // Fallback to just updating status if missing players/teams
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
                              icon: const Icon(Icons.how_to_reg_rounded, size: 22, color: Colors.white),
                              label: Text(
                                isCounty ? 'START COUNTY (GO TO SCOREBOARD)' : 'SELECT SQUADS (TEAM A & B)',
                                style: const TextStyle(
                                  fontSize: 15,
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
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // ── 3. LIVE MATCH CONTROLS ──
                      if (match.status == MatchStatus.live) ...[
                        _buildLiveStatusBanner(),
                        const SizedBox(height: 14),
                        if (canScore) ...[
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring'),
                              icon: const Icon(Icons.edit_note_rounded, size: 24, color: Colors.white),
                              label: const Text(
                                'OPEN LIVE SCORER CONSOLE',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, letterSpacing: 0.5, color: Colors.white),
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
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/live'),
                            icon: const Icon(Icons.stream_rounded, size: 22, color: Colors.white),
                            label: const Text(
                              'WATCH LIVE SCORES & STREAM',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── 4. COMPLETED MATCH RESULT ──
                      if (match.status == MatchStatus.completed) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFD97706).withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 38),
                              const SizedBox(height: 8),
                              Text(
                                match.resultText ?? 'Match Completed',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/summary'),
                            icon: const Icon(Icons.sports_score_rounded, color: Colors.white),
                            label: const Text('VIEW FULL MATCH SUMMARY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── 5. MATCH INFORMATION & DETAILS CARD (RESTRUCTURED) ──
                      _buildMatchInfoCard(match, isCounty),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: BEAUTIFUL STADIUM VS HERO BANNER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVsHeroCard(
    BuildContext context,
    Match match,
    Team? teamA,
    Team? teamB,
    int countA,
    int countB,
    bool isCounty,
  ) {
    final imageProviderA = _getImageProvider(teamA?.logoUrl);
    final imageProviderB = _getImageProvider(teamB?.logoUrl);

    final targetRuns = match.liveScore?['targetRuns'];
    final totalBalls = match.liveScore?['totalBalls'];

    final statusColor = match.status == MatchStatus.live
        ? const Color(0xFFEF4444)
        : match.status == MatchStatus.completed
            ? const Color(0xFF10B981)
            : const Color(0xFF3B82F6);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCounty
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF78350F)]
              : [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF0F2942)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCounty ? const Color(0xFFD97706).withOpacity(0.5) : const Color(0xFF38BDF8).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCounty ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Badges Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.6), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (match.status == MatchStatus.live) ...[
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        ),
                      ],
                      Text(
                        match.status.label.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),

                // Match Format Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCounty
                          ? [const Color(0xFFD97706), const Color(0xFFEF4444)]
                          : [const Color(0xFF2563EB), const Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isCounty ? Icons.bolt_rounded : Icons.sports_cricket_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        isCounty ? 'COUNTY DUEL' : 'TOURNAMENT MATCH',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // County Target Bar if available
          if (isCounty && targetRuns != null && totalBalls != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.track_changes_rounded, color: Color(0xFFFDE68A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'TARGET CHALLENGE: $targetRuns RUNS IN $totalBalls BALLS',
                    style: const TextStyle(
                      color: Color(0xFFFDE68A),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Teams / Persons VS Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Team / Person A
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isCounty ? const Color(0xFF60A5FA) : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          image: imageProviderA != null ? DecorationImage(image: imageProviderA, fit: BoxFit.cover) : null,
                        ),
                        alignment: Alignment.center,
                        child: imageProviderA == null
                            ? Text(
                                teamA?.shortName ?? match.teamA.substring(0, (match.teamA.length >= 2 ? 2 : 1)).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: isCounty ? const Color(0xFF1D4ED8) : const Color(0xFF1E3A8A),
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.teamA,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCounty
                              ? const Color(0xFF2563EB).withOpacity(0.3)
                              : (countA >= 2 ? Colors.white.withOpacity(0.18) : const Color(0xFFEF4444).withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isCounty ? '🏏 BATSMAN' : '$countA Players',
                          style: TextStyle(
                            color: isCounty ? const Color(0xFF93C5FD) : (countA >= 2 ? const Color(0xFF93C5FD) : const Color(0xFFFCA5A5)),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center VS Emblem
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isCounty
                          ? const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFEF4444)])
                          : const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)]),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: (isCounty ? const Color(0xFFD97706) : const Color(0xFF0284C7)).withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Color(0xFFFACC15),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Team / Person B
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isCounty ? const Color(0xFFFBBF24) : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          image: imageProviderB != null ? DecorationImage(image: imageProviderB, fit: BoxFit.cover) : null,
                        ),
                        alignment: Alignment.center,
                        child: imageProviderB == null
                            ? Text(
                                teamB?.shortName ?? match.teamB.substring(0, (match.teamB.length >= 2 ? 2 : 1)).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: isCounty ? const Color(0xFFB45309) : const Color(0xFF1E3A8A),
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.teamB,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCounty
                              ? const Color(0xFFD97706).withOpacity(0.3)
                              : (countB >= 2 ? Colors.white.withOpacity(0.18) : const Color(0xFFEF4444).withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isCounty ? '🎯 BOWLER' : '$countB Players',
                          style: TextStyle(
                            color: isCounty ? const Color(0xFFFDE68A) : (countB >= 2 ? const Color(0xFF93C5FD) : const Color(0xFFFCA5A5)),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Ground & Schedule Glass Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_rounded, color: Color(0xFF93C5FD), size: 15),
                    const SizedBox(width: 5),
                    Text(
                      match.venue.isNotEmpty ? match.venue : 'Cricket Ground',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.sports_cricket_rounded, color: Color(0xFFFDE68A), size: 15),
                    const SizedBox(width: 5),
                    Text(
                      '${match.totalOvers} Overs',
                      style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF93C5FD), size: 13),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('dd MMM • hh:mm a').format(match.matchDate),
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: TOSS / COUNTY CHALLENGE STATUS CARD
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
                  'County Challenge Active',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
          const SizedBox(height: 8),
          Text(
            '$tossWinner won the toss and elected to ${match.tossDecision?.label.toLowerCase() ?? 'bat'}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$battingFirst will bat first.',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: TOSS SETUP CARD
  // ─────────────────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(20),
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

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: REDESIGNED MATCH INFO CARD (CLEAN & COMPLETE)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMatchInfoCard(Match match, bool isCounty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Match Information',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          _buildInfoItem(
            icon: Icons.place_rounded,
            iconColor: const Color(0xFFEF4444),
            label: 'Ground / Venue',
            value: match.venue.isNotEmpty ? match.venue : 'Cricket Ground',
          ),
          _buildInfoItem(
            icon: Icons.sports_cricket_rounded,
            iconColor: const Color(0xFF16A34A),
            label: 'Match Format',
            value: isCounty
                ? 'County Duel (${match.liveScore?['countyMode'] ?? '1v1'}) • ${match.totalOvers} Overs'
                : '${match.totalOvers} Overs per side',
          ),
          if (isCounty && match.liveScore?['targetRuns'] != null)
            _buildInfoItem(
              icon: Icons.track_changes_rounded,
              iconColor: const Color(0xFFD97706),
              label: 'Target Quota',
              value: '${match.liveScore!['targetRuns']} Runs in ${match.liveScore!['totalBalls']} Balls',
            ),
          _buildInfoItem(
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF2563EB),
            label: 'Scheduled Date',
            value: DateFormat('EEEE, dd MMMM yyyy • hh:mm a').format(match.matchDate),
          ),
          _buildInfoItem(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF8B5CF6),
            label: 'Match Status',
            value: match.status.label,
          ),
          if (match.hasToss || isCounty)
            _buildInfoItem(
              icon: Icons.how_to_vote_rounded,
              iconColor: const Color(0xFF0D9488),
              label: 'Toss / Batting First',
              value: isCounty
                  ? '${match.teamA} (Batting First by County Rules)'
                  : '${match.tossWinnerId == match.teamAId ? match.teamA : match.teamB} (Elected to ${match.tossDecision?.label.toLowerCase()})',
            ),
          if (match.resultText != null && match.resultText!.isNotEmpty)
            _buildInfoItem(
              icon: Icons.emoji_events_rounded,
              iconColor: const Color(0xFFEAB308),
              label: 'Match Result',
              value: match.resultText!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
          const Text(' :  ', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  // ── LIVE STATUS BANNER ──
  Widget _buildLiveStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
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
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
