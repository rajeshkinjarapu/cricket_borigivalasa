import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';

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
  int _selectedSquadTabIndex = 0; // 0 for Team A, 1 for Team B

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

  Color _getRoleColor(PlayerRole role) {
    switch (role) {
      case PlayerRole.batter:
        return const Color(0xFF2563EB); // Blue
      case PlayerRole.bowler:
        return const Color(0xFF16A34A); // Green
      case PlayerRole.allRounder:
        return const Color(0xFF9333EA); // Purple
      case PlayerRole.wicketKeeper:
        return const Color(0xFFD97706); // Amber
    }
  }

  void _showPlayersRequiredDialog(BuildContext context, Match match, int teamACount, int teamBCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Players Required',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Both teams must have registered players before starting the match or recording the toss.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          match.teamA,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: teamACount >= 2 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$teamACount Players',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: teamACount >= 2 ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          match.teamB,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: teamBCount >= 2 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$teamBCount Players',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: teamBCount >= 2 ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (teamACount < 2)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/teams/${match.teamAId}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: Text('Add to ${match.teamA.split(" ").first}'),
            ),
          if (teamBCount < 2)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/teams/${match.teamBId}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: Text('Add to ${match.teamB.split(" ").first}'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveToss(Match match, int teamACount, int teamBCount) async {
    if (teamACount < 2 || teamBCount < 2) {
      _showPlayersRequiredDialog(context, match, teamACount, teamBCount);
      return;
    }

    if (_selectedTossWinner == null || _selectedDecision == null) return;
    setState(() => _isSavingToss = true);
    final ok = await ref.read(matchControllerProvider.notifier).setToss(
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
      tossWinnerTeamId: _selectedTossWinner!,
      tossDecision: _selectedDecision!,
    );
    if (mounted) {
      setState(() => _isSavingToss = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toss recorded successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  Future<void> _deleteMatch(BuildContext context, Match match) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Match?',
      message: 'Are you sure you want to permanently delete this match (${match.teamA} vs ${match.teamB})? All scoring data for this match will be lost.',
      confirmLabel: 'Delete Match',
      destructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      final ok = await ref.read(matchControllerProvider.notifier).delete(widget.tournamentId, widget.matchId);
      if (mounted) {
        setState(() => _isDeleting = false);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Match deleted successfully'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete match'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    )));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return matchAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
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
            body: const Center(child: Text('Match not found or has been deleted.')),
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
        final hasEnoughPlayers = teamAPlayers.length >= 2 && teamBPlayers.length >= 2;

        final isTossDone = match.hasToss;
        final tossWinnerName = match.tossWinnerId == match.teamAId ? match.teamA : match.teamB;
        final battingFirstTeam = match.tossDecision == TossDecision.bat
            ? (match.tossWinnerId == match.teamAId ? match.teamA : match.teamB)
            : (match.tossWinnerId == match.teamAId ? match.teamB : match.teamA);

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Match Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Colors.white),
            ),
            actions: [
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Edit Match',
                  onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/edit'),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/edit');
                    } else if (val == 'delete') {
                      _deleteMatch(context, match);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 10),
                          Text('Edit Match Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever_rounded, size: 20, color: Color(0xFFDC2626)),
                          SizedBox(width: 10),
                          Text('Delete Match', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
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
                      // ── HERO VS BANNER WITH TEAM PHOTOS & PLAYER COUNTS ──
                      _buildVsHeroCard(context, match, teamA, teamB, teamAPlayers.length, teamBPlayers.length),
                      const SizedBox(height: 16),

                      // ── SCHEDULED MATCH STATE (TOSS SETUP) ──
                      if (match.status == MatchStatus.scheduled) ...[
                        if (!isTossDone && isAdmin)
                          _buildTossSetupCard(context, match, teamAPlayers.length, teamBPlayers.length, hasEnoughPlayers),
                        if (isTossDone)
                          _buildTossRecordedCard(context, match, tossWinnerName, battingFirstTeam),
                        const SizedBox(height: 16),
                        if (isTossDone && isAdmin)
                          ElevatedButton.icon(
                            onPressed: () {
                              if (!hasEnoughPlayers) {
                                _showPlayersRequiredDialog(context, match, teamAPlayers.length, teamBPlayers.length);
                                return;
                              }
                              context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring');
                            },
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                            label: const Text(
                              'START SCORING NOW',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: hasEnoughPlayers ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 3,
                            ),
                          ),
                      ],

                      // ── LIVE MATCH STATE ──
                      if (match.status == MatchStatus.live) ...[
                        _buildLiveStatusBanner(),
                        const SizedBox(height: 14),
                        if (isAdmin)
                          ElevatedButton.icon(
                            onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring'),
                            icon: const Icon(Icons.edit_note_rounded, size: 24),
                            label: const Text('OPEN LIVE SCORER CONSOLE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFEA580C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 3,
                            ),
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/live'),
                          icon: const Icon(Icons.stream_rounded, size: 22),
                          label: const Text('WATCH LIVE SCORES & STREAM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionOutlineButton(
                                icon: Icons.scoreboard_outlined,
                                label: 'Scorecard',
                                onTap: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scorecard'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionOutlineButton(
                                icon: Icons.bar_chart_rounded,
                                label: 'Match Charts',
                                onTap: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/charts'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── COMPLETED MATCH STATE ──
                      if (match.status == MatchStatus.completed) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 36),
                              const SizedBox(height: 8),
                              Text(
                                match.resultText ?? 'Match Completed',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/summary'),
                          icon: const Icon(Icons.sports_score_rounded),
                          label: const Text('VIEW MATCH SUMMARY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionOutlineButton(
                                icon: Icons.scoreboard_outlined,
                                label: 'Full Scorecard',
                                onTap: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scorecard'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionOutlineButton(
                                icon: Icons.bar_chart_rounded,
                                label: 'Match Charts',
                                onTap: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/charts'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ── PREMIUM VS HERO BANNER WITH TEAM LOGOS ──
  Widget _buildVsHeroCard(BuildContext context, Match match, Team? teamA, Team? teamB, int countA, int countB) {
    final imageProviderA = _getImageProvider(teamA?.logoUrl);
    final imageProviderB = _getImageProvider(teamB?.logoUrl);

    final statusColor = match.status == MatchStatus.live
        ? const Color(0xFFEF4444)
        : match.status == MatchStatus.completed
            ? const Color(0xFF10B981)
            : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Clean Royal Blue
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.25),
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
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ],
                Text(
                  match.status.label.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Teams VS Row with Logos & Squad Count
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                        image: imageProviderA != null ? DecorationImage(image: imageProviderA, fit: BoxFit.cover) : null,
                      ),
                      alignment: Alignment.center,
                      child: imageProviderA == null
                          ? Text(
                              teamA?.shortName ?? match.teamA.substring(0, (match.teamA.length >= 2 ? 2 : 1)).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 20),
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
                        color: countA >= 2 ? Colors.white.withOpacity(0.18) : const Color(0xFFEF4444).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$countA Players',
                        style: TextStyle(
                          color: countA >= 2 ? const Color(0xFF93C5FD) : const Color(0xFFFCA5A5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // VS Emblem
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Color(0xFFFACC15), // Bold Gold
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Team B
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                        image: imageProviderB != null ? DecorationImage(image: imageProviderB, fit: BoxFit.cover) : null,
                      ),
                      alignment: Alignment.center,
                      child: imageProviderB == null
                          ? Text(
                              teamB?.shortName ?? match.teamB.substring(0, (match.teamB.length >= 2 ? 2 : 1)).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 20),
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
                        color: countB >= 2 ? Colors.white.withOpacity(0.18) : const Color(0xFFEF4444).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$countB Players',
                        style: TextStyle(
                          color: countB >= 2 ? const Color(0xFF93C5FD) : const Color(0xFFFCA5A5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Venue, Overs & Date Details
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.place_rounded, color: Color(0xFF93C5FD), size: 15),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  match.venue.isNotEmpty ? match.venue : 'Cricket Ground',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Icon(Icons.sports_cricket_rounded, color: Color(0xFF93C5FD), size: 15),
              const SizedBox(width: 4),
              Text(
                '${match.totalOvers} Overs',
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_rounded, color: Color(0xFF93C5FD), size: 13),
              const SizedBox(width: 5),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(match.matchDate),
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TOSS SETUP CARD ──
  Widget _buildTossSetupCard(BuildContext context, Match match, int countA, int countB, bool hasEnough) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 8),
              Text(
                'Toss Setup',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Who won the toss?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF475569)),
          ),
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
          const SizedBox(height: 18),
          const Text(
            'What did they choose?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  '🏏 Batting',
                  _selectedDecision == TossDecision.bat,
                  () => setState(() => _selectedDecision = TossDecision.bat),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceChip(
                  '🎯 Bowling',
                  _selectedDecision == TossDecision.bowl,
                  () => setState(() => _selectedDecision = TossDecision.bowl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_selectedTossWinner != null && _selectedDecision != null && !_isSavingToss)
                ? () => _saveToss(match, countA, countB)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              elevation: 0,
            ),
            child: _isSavingToss
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Save Toss Result',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }

  // ── TOSS RECORDED CARD ──
  Widget _buildTossRecordedCard(BuildContext context, Match match, String tossWinner, String battingFirst) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 30),
          const SizedBox(height: 8),
          Text(
            '$tossWinner won the toss and elected to ${match.tossDecision!.label.toLowerCase()}.',
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
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── OUTLINE ACTION BUTTON ──
  Widget _buildActionOutlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E3A8A),
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
