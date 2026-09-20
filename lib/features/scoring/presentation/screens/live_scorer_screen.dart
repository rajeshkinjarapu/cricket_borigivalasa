import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../data/models/ball_event.dart';
import '../../data/models/innings.dart';
import '../../data/repositories/scoring_repository.dart';
import '../providers/scoring_providers.dart';
import '../widgets/over_end_sheet.dart';
import '../widgets/wicket_sheet.dart';
import 'innings_setup_screen.dart';

class LiveScorerScreen extends ConsumerWidget {
  const LiveScorerScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  final String tournamentId, matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider((
      tournamentId: tournamentId,
      matchId: matchId,
    )));
    final match = matchAsync.value;
    if (match != null &&
        match.status != MatchStatus.live &&
        match.status != MatchStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(matchRepositoryProvider).updatePartial(
          tournamentId: tournamentId,
          matchId: matchId,
          data: {
            'status': MatchStatus.live.name,
            'startedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });
    }

    final i1 = ref.watch(inningsProvider((tournamentId: tournamentId, matchId: matchId, innings: 1)));
    final i2 = ref.watch(inningsProvider((tournamentId: tournamentId, matchId: matchId, innings: 2)));

    return i1.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: const Text('Live Scorer'),
        ),
        body: Center(child: Text('Error loading match: $e')),
      ),
      data: (inn1) {
        if (inn1 == null) {
          return InningsSetupScreen(tournamentId: tournamentId, matchId: matchId, inningsNumber: 1);
        }
        if (inn1.isComplete) {
          return i2.when(
            loading: () => const Scaffold(
              backgroundColor: Color(0xFFF8FAFC),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              ),
            ),
            error: (e, _) => Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                title: const Text('Live Scorer'),
              ),
              body: Center(child: Text('Error loading innings 2: $e')),
            ),
            data: (inn2) {
              if (inn2 == null) {
                return InningsSetupScreen(
                  tournamentId: tournamentId,
                  matchId: matchId,
                  inningsNumber: 2,
                  targetRuns: inn1.runs + 1,
                );
              }
              return _LiveScorerEngine(tournamentId: tournamentId, matchId: matchId, innings: inn2);
            },
          );
        }
        return _LiveScorerEngine(tournamentId: tournamentId, matchId: matchId, innings: inn1);
      },
    );
  }
}

class _LiveScorerEngine extends ConsumerStatefulWidget {
  const _LiveScorerEngine({
    required this.tournamentId,
    required this.matchId,
    required this.innings,
  });

  final String tournamentId, matchId;
  final Innings innings;

  @override
  ConsumerState<_LiveScorerEngine> createState() => _LiveScorerEngineState();
}

class _LiveScorerEngineState extends ConsumerState<_LiveScorerEngine> {
  bool _isProcessing = false;
  int? _promptedOverNumber;
  InningsKey get _k => (tournamentId: widget.tournamentId, matchId: widget.matchId, innings: widget.innings.inningsNumber);

  Future<void> _recordBall(BallEvent ball) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final match = ref.read(matchDetailProvider((
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      ))).value;
      final maxOvers = (match != null && match.totalOvers > 0)
          ? match.totalOvers
          : ref.read(matchMaxOversProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));

      await ref.read(scoringRepositoryProvider).recordBall(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: widget.innings.inningsNumber,
        innings: widget.innings,
        ball: ball,
        maxOvers: maxOvers,
        playersPerSide: playersPerSide,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _undoLastBall() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _promptedOverNumber = null;
    });
    try {
      final match = ref.read(matchDetailProvider((
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      ))).value;
      final maxOvers = (match != null && match.totalOvers > 0)
          ? match.totalOvers
          : ref.read(matchMaxOversProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));

      await ref.read(scoringRepositoryProvider).undoLastBall(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: widget.innings.inningsNumber,
        innings: widget.innings,
        maxOvers: maxOvers,
        playersPerSide: playersPerSide,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Last ball undone successfully!'),
            duration: Duration(milliseconds: 1500),
            backgroundColor: Color(0xFFEA580C),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _swapStrike(Innings live) async {
    if (_isProcessing || live.strikerId == null || live.nonStrikerId == null) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(scoringRepositoryProvider).swapStrike(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: live.inningsNumber,
        innings: live,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Strike rotated!'),
            duration: Duration(milliseconds: 1200),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _manualChangeBowler(Innings live) async {
    final players = ref.read(teamPlayersProvider(live.bowlingTeamId)).value ?? [];
    if (players.isEmpty) return;

    final selected = await showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_baseball_rounded, color: Color(0xFF1E3A8A), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Select Bowler (${live.bowlingTeamName})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: players.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (c, idx) {
                  final p = players[idx];
                  final isCurrent = p.id == live.currentBowlerId;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? const Color(0xFF16A34A) : const Color(0xFF1E3A8A).withOpacity(0.1),
                      child: Icon(Icons.sports_cricket_rounded, color: isCurrent ? Colors.white : const Color(0xFF1E3A8A), size: 18),
                    ),
                    title: Text(p.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600)),
                    subtitle: Text(p.role.label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    trailing: isCurrent
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Current', style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        : null,
                    onTap: () => Navigator.pop(ctx, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await ref.read(scoringRepositoryProvider).setCurrentBowler(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: live.inningsNumber,
        bowler: selected,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected.name} is now bowling!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  Future<void> _handleOverCompletion(Innings live) async {
    final match = ref.read(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    ))).value;
    final maxOvers = (match != null && match.totalOvers > 0)
        ? match.totalOvers
        : ref.read(matchMaxOversProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));

    if (live.legalBalls >= maxOvers * 6 || live.legalBalls == 0 || live.legalBalls % 6 != 0) return;

    final completedOver = live.legalBalls ~/ 6;
    if (_promptedOverNumber == completedOver) return;
    _promptedOverNumber = completedOver;

    final players = ref.read(teamPlayersProvider(live.bowlingTeamId)).value ?? [];
    if (players.isEmpty) return;

    final b = await showOverEndSheet(
      context,
      completedOver: completedOver,
      bowlingTeamPlayers: players,
      excludeBowlerId: live.currentBowlerId,
    );

    if (b == null) return;

    await ref.read(scoringRepositoryProvider).setCurrentBowler(
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
      inningsNumber: live.inningsNumber,
      bowler: b,
    );
  }

  Future<void> _wicket() async {
    final inn = widget.innings;
    if (inn.strikerId == null || inn.currentBowlerId == null) return;

    final bp = ref.read(teamPlayersProvider(inn.bowlingTeamId)).value ?? [];
    final batP = ref.read(teamPlayersProvider(inn.battingTeamId)).value ?? [];
    final rows = ref.read(battingScorecardProvider(_k)).value ?? [];

    final dismissed = rows.where((r) => r.isOut).map((r) => r.playerId).toSet();
    final avail = batP.where((p) => !dismissed.contains(p.id) && p.id != inn.strikerId && p.id != inn.nonStrikerId).toList();

    final r = await showWicketSheet(
      context,
      strikerId: inn.strikerId!,
      strikerName: inn.strikerName ?? '',
      nonStrikerId: inn.nonStrikerId ?? '',
      nonStrikerName: inn.nonStrikerName ?? '',
      bowlingTeamPlayers: bp,
      availableBatsmen: avail,
    );

    if (r == null) return;

    await _recordBall(BallEvent(
      isWicket: true,
      wicketType: r.type,
      dismissedPlayerId: r.dismissedPlayerId,
      dismissedPlayerName: r.dismissedPlayerName,
      fielderId: r.fielderId,
      fielderName: r.fielderName,
      batsmanId: inn.strikerId!,
      batsmanName: inn.strikerName ?? '',
      bowlerId: inn.currentBowlerId!,
      bowlerName: inn.currentBowlerName ?? '',
      newBatsmanId: r.newBatsmanId,
      newBatsmanName: r.newBatsmanName,
      timestamp: DateTime.now(),
    ));
  }

  Future<int?> _customRuns() async {
    final opts = [0, 1, 2, 3, 4, 5, 6, 7];
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Batsman Runs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: opts.map((r) => SizedBox(
                width: 68,
                height: 68,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('$r', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runs(int r) async {
    final i = widget.innings;
    if (i.currentBowlerId == null || i.strikerId == null) return;
    await _recordBall(BallEvent(
      batRuns: r,
      batsmanId: i.strikerId!,
      batsmanName: i.strikerName ?? '',
      bowlerId: i.currentBowlerId!,
      bowlerName: i.currentBowlerName ?? '',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _wide() async {
    final r = await _showRunsDialog('Wide Ball (Extra Runs)', includeZero: true);
    if (r == null) return;
    final i = widget.innings;
    if (i.currentBowlerId == null || i.strikerId == null) return;
    await _recordBall(BallEvent(
      extraRuns: r,
      extraType: ExtraType.wide,
      batsmanId: i.strikerId!,
      batsmanName: i.strikerName ?? '',
      bowlerId: i.currentBowlerId!,
      bowlerName: i.currentBowlerName ?? '',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _noball() async {
    final r = await _showRunsDialog('No Ball (Bat Runs)', includeZero: true);
    if (r == null) return;
    final i = widget.innings;
    if (i.currentBowlerId == null || i.strikerId == null) return;
    await _recordBall(BallEvent(
      batRuns: r,
      extraType: ExtraType.noball,
      batsmanId: i.strikerId!,
      batsmanName: i.strikerName ?? '',
      bowlerId: i.currentBowlerId!,
      bowlerName: i.currentBowlerName ?? '',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _byes({required bool isLegBye}) async {
    final r = await _showRunsDialog(isLegBye ? 'Leg Byes (Runs)' : 'Byes (Runs)', includeZero: false);
    if (r == null) return;
    final i = widget.innings;
    if (i.currentBowlerId == null || i.strikerId == null) return;
    await _recordBall(BallEvent(
      extraRuns: r,
      extraType: isLegBye ? ExtraType.legbye : ExtraType.bye,
      batsmanId: i.strikerId!,
      batsmanName: i.strikerName ?? '',
      bowlerId: i.currentBowlerId!,
      bowlerName: i.currentBowlerName ?? '',
      timestamp: DateTime.now(),
    ));
  }

  Future<int?> _showRunsDialog(String title, {bool includeZero = true}) {
    final opts = includeZero ? [0, 1, 2, 3, 4, 6] : [1, 2, 3, 4];
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            const Text('Select number of runs scored on this delivery', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: opts.map((r) => SizedBox(
                width: 68,
                height: 68,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('$r', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(inningsProvider(_k));
    final live = a.value ?? widget.innings;
    final match = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    ))).value;
    final maxOvers = (match != null && match.totalOvers > 0)
        ? match.totalOvers
        : ref.watch(matchMaxOversProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));

    final overEnd = live.legalBalls > 0 && live.legalBalls % 6 == 0 && live.legalBalls < maxOvers * 6 && !live.isComplete;
    if (overEnd && _promptedOverNumber != (live.legalBalls ~/ 6)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleOverCompletion(live);
      });
    }

    final batRows = ref.watch(battingScorecardProvider(_k)).value ?? [];
    final bowlRows = ref.watch(bowlingScorecardProvider(_k)).value ?? [];

    final striker = batRows.where((r) => r.playerId == live.strikerId).firstOrNull;
    final nonStriker = batRows.where((r) => r.playerId == live.nonStrikerId).firstOrNull;
    final currentBowler = bowlRows.where((r) => r.playerId == live.currentBowlerId).firstOrNull;

    final totalExtras = live.wides + live.noballs + live.byes + live.legbyes;
    final projectedScore = live.legalBalls > 0 ? ((live.runs / live.legalBalls) * (maxOvers * 6)).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Scoring Console',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              '${live.battingTeamName} vs ${live.bowlingTeamName} • Innings ${live.inningsNumber}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF93C5FD), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          // ── PROMINENT SCORECARD BUTTON ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              onTap: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scorecard'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38, width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.scoreboard_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Scorecard',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            tooltip: 'Rotate Strike',
            onPressed: () => _swapStrike(live),
          ),
          IconButton(
            icon: const Icon(Icons.sports_baseball_rounded, color: Colors.white),
            tooltip: 'Change Bowler',
            onPressed: () => _manualChangeBowler(live),
          ),
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
            tooltip: 'Match Settings / Overs',
            onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/edit'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP SCROLLABLE CRICKET DASHBOARD ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                children: [
                  // 1. ── HERO STADIUM SCOREBOARD CARD (ROYAL SAPPHIRE GRADIENT) ──
                  _buildHeroScoreboardCard(live, maxOvers, totalExtras, projectedScore),
                  const SizedBox(height: 12),

                  // 2. ── BATSMEN ON CREASE (STRIKER & NON-STRIKER) ──
                  _buildBatsmenSection(striker, nonStriker, live),
                  const SizedBox(height: 12),

                  // 3. ── CURRENT BOWLER CARD ──
                  _buildBowlerSection(currentBowler, live),
                  const SizedBox(height: 12),

                  // 4. ── THIS OVER TIMELINE (LIVE BALLS) ──
                  _buildThisOverSection(live),
                ],
              ),
            ),

            // ── TACTILE ERGONOMIC SCORING KEYPAD CONSOLE ──
            _buildScoringKeypad(live),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. HERO SCOREBOARD CARD (ROYAL SAPPHIRE STADIUM GRADIENT)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeroScoreboardCard(Innings live, int maxOvers, int totalExtras, int projectedScore) {
    final crr = live.runRate;
    final totalBalls = maxOvers * 6;
    final ballsRemaining = totalBalls - live.legalBalls;
    final target = live.targetRuns;
    final runsNeeded = target != null ? target - live.runs : null;
    final rrr = (runsNeeded != null && ballsRemaining > 0 && runsNeeded > 0)
        ? (runsNeeded / ballsRemaining) * 6
        : null;

    final progress = totalBalls > 0 ? (live.legalBalls / totalBalls).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.38),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        children: [
          // Team Name & Innings Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_cricket_rounded, color: Color(0xFFFDE047), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    live.battingTeamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${live.inningsNumber}${live.inningsNumber == 1 ? "st" : "nd"} Innings',
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Glowing Runs / Wickets & Overs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${live.runs}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
              ),
              Text(
                '/${live.wickets}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFCA5A5), // Soft Scarlet Red
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(
                  '${live.oversText} / $maxOvers ov',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overs Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              minHeight: 4.5,
            ),
          ),
          const SizedBox(height: 12),

          // Match Situation Glass Row (Target / CRR / RRR / Extras)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildScoreStatItem('CRR', crr.toStringAsFixed(2), color: const Color(0xFF38BDF8))),
                if (target != null && runsNeeded != null) ...[
                  Container(width: 1, height: 20, color: Colors.white12),
                  Expanded(child: _buildScoreStatItem('NEED', '$runsNeeded off $ballsRemaining b', color: const Color(0xFFFDE047))),
                  if (rrr != null) ...[
                    Container(width: 1, height: 20, color: Colors.white12),
                    Expanded(child: _buildScoreStatItem('RRR', rrr.toStringAsFixed(2), color: const Color(0xFFF87171))),
                  ],
                ] else ...[
                  Container(width: 1, height: 20, color: Colors.white12),
                  Expanded(child: _buildScoreStatItem('PROJ', '$projectedScore', color: const Color(0xFF4ADE80))),
                ],
                Container(width: 1, height: 20, color: Colors.white12),
                Expanded(child: _buildScoreStatItem('EXTRAS', '$totalExtras (w${live.wides} nb${live.noballs})', color: const Color(0xFFE2E8F0))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStatItem(String label, String val, {required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFCBD5E1), letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. BATSMEN SECTION (STRIKER & NON-STRIKER)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBatsmenSection(BattingScorecardRow? striker, BattingScorecardRow? nonStriker, Innings live) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.sports_cricket_rounded, size: 16, color: Color(0xFF1E3A8A)),
                SizedBox(width: 6),
                Text(
                  'BATSMEN ON CREASE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.5),
                ),
              ],
            ),
            InkWell(
              onTap: () => _swapStrike(live),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 4),
                    Text(
                      'Swap Strike',
                      style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Batsmen Cards Row
        Row(
          children: [
            Expanded(child: _buildBatsmanCard(striker, isStriker: true)),
            const SizedBox(width: 10),
            Expanded(child: _buildBatsmanCard(nonStriker, isStriker: false)),
          ],
        ),
      ],
    );
  }

  Widget _buildBatsmanCard(BattingScorecardRow? batter, {required bool isStriker}) {
    final runs = batter?.runs ?? 0;
    final balls = batter?.balls ?? 0;
    final sr = balls > 0 ? (runs * 100 / balls).toStringAsFixed(1) : '0.0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStriker ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
          width: isStriker ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isStriker ? const Color(0xFF16A34A).withOpacity(0.12) : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isStriker ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStriker) ...[
                      const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      isStriker ? 'ON STRIKE' : 'NON-STRIKER',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isStriker ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (isStriker) const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
            ],
          ),
          const SizedBox(height: 8),

          // Batsman Name
          Text(
            batter?.playerName ?? 'Selecting...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isStriker ? const Color(0xFF065F46) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          // Big Score & Balls
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$runs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isStriker ? const Color(0xFF15803D) : const Color(0xFF1E293B),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($balls)',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 6),

          // Boundary Breakdown & SR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4s: ${batter?.fours ?? 0}  6s: ${batter?.sixes ?? 0}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              Text('SR: $sr', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. CURRENT BOWLER SECTION
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBowlerSection(BowlingScorecardRow? bowler, Innings live) {
    final balls = bowler?.balls ?? 0;
    final oversText = '${balls ~/ 6}.${balls % 6}';
    final econ = balls > 0 ? ((bowler?.runs ?? 0) * 6 / balls).toStringAsFixed(2) : '0.00';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_baseball_rounded, color: Color(0xFFDC2626), size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bowler?.playerName ?? 'Unknown Bowler',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _manualChangeBowler(live),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 13, color: Color(0xFFDC2626)),
                      SizedBox(width: 3),
                      Text(
                        'Change',
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bowler Spell Stats Table
          Row(
            children: [
              Expanded(child: _buildBowlerStatCol('O', oversText)),
              Expanded(child: _buildBowlerStatCol('M', '${bowler?.maidens ?? 0}')),
              Expanded(child: _buildBowlerStatCol('R', '${bowler?.runs ?? 0}')),
              Expanded(child: _buildBowlerStatCol('W', '${bowler?.wickets ?? 0}', isWicket: true)),
              Expanded(child: _buildBowlerStatCol('ECON', econ)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBowlerStatCol(String title, String val, {bool isWicket = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isWicket ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. THIS OVER TIMELINE
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildThisOverSection(Innings live) {
    final currentOverNum = (live.legalBalls ~/ 6) + 1;
    final ballsAsync = ref.watch(currentOverBallsProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
      innings: live.inningsNumber,
      overNumber: currentOverNum,
    )));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THIS OVER (OVER $currentOverNum)',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.6),
              ),
              ballsAsync.maybeWhen(
                data: (balls) {
                  final overRuns = balls.fold<int>(0, (s, b) => s + b.batRuns + b.extraRuns);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '$overRuns Runs',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ballsAsync.when(
            loading: () => const SizedBox(
              height: 36,
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A)))),
            ),
            error: (_, __) => const SizedBox(
              height: 36,
              child: Center(child: Text('Error loading over', style: TextStyle(color: Colors.grey, fontSize: 12))),
            ),
            data: (balls) {
              if (balls.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: const Text(
                    '⚡ Ready for 1st ball of this over',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                );
              }
              return SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: balls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final b = balls[index];
                    return _buildBallChip(b);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBallChip(BallEvent b) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF334155);
    String text = b.shortLabel;

    if (b.isWicket) {
      bg = const Color(0xFFDC2626); // Crimson
      fg = Colors.white;
    } else if (b.batRuns == 4) {
      bg = const Color(0xFF2563EB); // Royal Blue
      fg = Colors.white;
    } else if (b.batRuns == 6) {
      bg = const Color(0xFF7C3AED); // Royal Purple
      fg = Colors.white;
    } else if (b.extraType != ExtraType.none) {
      bg = const Color(0xFFD97706); // Amber
      fg = Colors.white;
    } else if (b.batRuns > 0) {
      bg = const Color(0xFF16A34A); // Emerald
      fg = Colors.white;
    }

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: bg.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: text.length > 2 ? 10.5 : 13),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TACTILE ERGONOMIC SCORING KEYPAD CONSOLE (FLOATING CARD DESIGN)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildScoringKeypad(Innings live) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomInset > 0 ? bottomInset + 6 : 14.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: EdgeInsets.fromLTRB(10, 12, 10, bottomPadding > 14 ? bottomPadding : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Runs Buttons (0, 1, 2, 3, 4, 6)
          Row(
            children: [
              _buildRunButton(0, label: '0'),
              _buildRunButton(1, label: '1'),
              _buildRunButton(2, label: '2'),
              _buildRunButton(3, label: '3'),
              _buildRunButton(4, label: '4', isFour: true),
              _buildRunButton(6, label: '6', isSix: true),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Extras & Wicket Buttons (WD, NB, BYE, LB, OUT)
          Row(
            children: [
              _buildActionButton('WD', _wide, color: const Color(0xFFD97706)),
              _buildActionButton('NB', _noball, color: const Color(0xFFD97706)),
              _buildActionButton('BYE', () => _byes(isLegBye: false), color: const Color(0xFF475569)),
              _buildActionButton('LB', () => _byes(isLegBye: true), color: const Color(0xFF475569)),
              _buildActionButton('OUT 🎯', _wicket, color: const Color(0xFFDC2626), isOut: true),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Quick Scorer Controls (Swap Strike, Bowler, + Runs, Undo)
          Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _swapStrike(live),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                  label: const Text('STRIKE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _manualChangeBowler(live),
                  icon: const Icon(Icons.sports_baseball_rounded, size: 15),
                  label: const Text('BOWLER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final r = await _customRuns();
                          if (r != null) _runs(r);
                        },
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('+RUNS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _undoLastBall,
                  icon: const Icon(Icons.undo_rounded, size: 15),
                  label: const Text('UNDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(int runs, {required String label, bool isFour = false, bool isSix = false}) {
    Color bg = const Color(0xFF1E293B);
    Color fg = Colors.white;

    if (isFour) {
      bg = const Color(0xFF059669); // Emerald Green
    } else if (isSix) {
      bg = const Color(0xFF7C3AED); // Royal Purple
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _runs(runs),
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2.5,
              shadowColor: bg.withOpacity(0.4),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap, {required Color color, bool isOut = false}) {
    return Expanded(
      flex: isOut ? 6 : 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              shadowColor: color.withOpacity(0.35),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isOut ? 12 : 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
