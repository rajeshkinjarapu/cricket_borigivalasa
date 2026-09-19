import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../data/models/ball_event.dart';
import '../../data/models/innings.dart';
import '../../data/repositories/scoring_repository.dart';
import '../providers/scoring_providers.dart';
import '../widgets/over_end_sheet.dart';
import '../widgets/wicket_sheet.dart';
import 'innings_setup_screen.dart';

class LiveScorerScreen extends ConsumerWidget {
  const LiveScorerScreen({super.key, required this.tournamentId, required this.matchId});
  final String tournamentId, matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i1 = ref.watch(inningsProvider((tournamentId: tournamentId, matchId: matchId, innings: 1)));
    final i2 = ref.watch(inningsProvider((tournamentId: tournamentId, matchId: matchId, innings: 2)));

    return i1.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: const Text('Live Scorer'),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (inn1) {
        if (inn1 == null) {
          return InningsSetupScreen(tournamentId: tournamentId, matchId: matchId, inningsNumber: 1);
        }
        if (inn1.isComplete) {
          return i2.when(
            loading: () => const Scaffold(
              backgroundColor: Color(0xFFF1F5F9),
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(
              backgroundColor: const Color(0xFFF1F5F9),
              appBar: AppBar(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                title: const Text('Live Scorer'),
              ),
              body: Center(child: Text('Error: $e')),
            ),
            data: (inn2) {
              if (inn2 == null) {
                return InningsSetupScreen(tournamentId: tournamentId, matchId: matchId, inningsNumber: 2, targetRuns: inn1.runs + 1);
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
  const _LiveScorerEngine({required this.tournamentId, required this.matchId, required this.innings});
  final String tournamentId, matchId;
  final Innings innings;

  @override
  ConsumerState<_LiveScorerEngine> createState() => _LiveScorerEngineState();
}

class _LiveScorerEngineState extends ConsumerState<_LiveScorerEngine> {
  bool _isProcessing = false;
  InningsKey get _k => (tournamentId: widget.tournamentId, matchId: widget.matchId, innings: widget.innings.inningsNumber);

  Future<void> _recordBall(BallEvent ball) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(scoringRepositoryProvider).recordBall(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: widget.innings.inningsNumber,
        innings: widget.innings,
        ball: ball,
        maxOvers: ref.read(maxOversProvider(widget.tournamentId)),
        playersPerSide: playersPerSide,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _undoLastBall() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(scoringRepositoryProvider).undoLastBall(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: widget.innings.inningsNumber,
        innings: widget.innings,
        maxOvers: ref.read(maxOversProvider(widget.tournamentId)),
        playersPerSide: playersPerSide,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleOverCompletion() async {
    final maxOvers = ref.read(maxOversProvider(widget.tournamentId));
    final inn = widget.innings;
    if (inn.legalBalls >= maxOvers * 6 || inn.legalBalls == 0 || inn.legalBalls % 6 != 0) return;

    final players = ref.read(teamPlayersProvider(inn.bowlingTeamId)).value ?? [];
    if (players.isEmpty) return;

    final b = await showOverEndSheet(
      context,
      completedOver: inn.legalBalls ~/ 6,
      bowlingTeamPlayers: players,
      excludeBowlerId: inn.currentBowlerId,
    );
    
    if (b == null) return;
    
    await ref.read(scoringRepositoryProvider).setCurrentBowler(
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
      inningsNumber: inn.inningsNumber,
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
    final r = await _showRunsDialog('Wide + Extra Runs');
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
    final r = await _showRunsDialog('No Ball + Runs');
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
    final r = await _showRunsDialog(isLegBye ? 'Leg Byes' : 'Byes', includeZero: false);
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
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: opts.map((r) => SizedBox(
                width: 72,
                height: 72,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context, r),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: Text('$r', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
    final max = ref.read(maxOversProvider(widget.tournamentId));
    
    final overEnd = live.legalBalls > 0 && live.legalBalls % 6 == 0 && live.legalBalls < max * 6 && !live.isComplete;
    if (overEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleOverCompletion();
      });
    }

    final batRows = ref.watch(battingScorecardProvider(_k)).value ?? [];
    final bowlRows = ref.watch(bowlingScorecardProvider(_k)).value ?? [];
    
    final striker = batRows.where((r) => r.playerId == live.strikerId).firstOrNull;
    final nonStriker = batRows.where((r) => r.playerId == live.nonStrikerId).firstOrNull;
    final currentBowler = bowlRows.where((r) => r.playerId == live.currentBowlerId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Top Header
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Live Scoring - ${live.battingTeamShort ?? live.battingTeamName}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SCOREBOARD (Dark Slate Neutral Card - Not Blue)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark Slate
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    live.battingTeamName.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${live.runs}/${live.wickets}',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '(${live.oversText} ov)',
                        style: const TextStyle(fontSize: 18, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('CRR: ${live.runRate.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      if (live.targetRuns != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF78350F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Target: ${live.targetRuns}', style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 2. MIDDLE AREA (BATSMEN & BOWLER)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildBatterCard(striker, isStriker: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildBatterCard(nonStriker, isStriker: false)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildBowlerCard(currentBowler),
                  const SizedBox(height: 16),
                  const Text('Current Over', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildCurrentOverTimeline(live),
                ],
              ),
            ),

            // 3. SCORING KEYPAD
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _runBtn(0), _runBtn(1), _runBtn(2), _runBtn(3), _runBtn(4, color: const Color(0xFF059669)), _runBtn(6, color: const Color(0xFF7C3AED)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _actionBtn('WD', _wide, color: const Color(0xFFD97706)),
                      _actionBtn('NB', _noball, color: const Color(0xFFD97706)),
                      _actionBtn('BYE', () => _byes(isLegBye: false), color: const Color(0xFF64748B)),
                      _actionBtn('LB', () => _byes(isLegBye: true), color: const Color(0xFF64748B)),
                      _actionBtn('OUT', _wicket, color: const Color(0xFFDC2626)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _undoLastBall,
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('UNDO BALL', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEA580C),
                            side: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterCard(BattingScorecardRow? batter, {required bool isStriker}) {
    return Card(
      elevation: 0,
      color: isStriker ? const Color(0xFFF0FDF4) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isStriker ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0), width: isStriker ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    batter?.playerName ?? 'Selecting...',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isStriker ? const Color(0xFF166534) : const Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isStriker) const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${batter?.runs ?? 0}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isStriker ? const Color(0xFF166534) : const Color(0xFF0F172A))),
                const SizedBox(width: 4),
                Text('(${batter?.balls ?? 0}b)', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text('4s: ${batter?.fours ?? 0}  6s: ${batter?.sixes ?? 0}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBowlerCard(BowlingScorecardRow? bowler) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BOWLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(bowler?.playerName ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                _stat('O', _calcOvers(bowler?.balls ?? 0)),
                _stat('M', '${bowler?.maidens ?? 0}'),
                _stat('R', '${bowler?.runs ?? 0}'),
                _stat('W', '${bowler?.wickets ?? 0}', isWicket: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {bool isWicket = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isWicket ? Colors.red : Colors.black87)),
        ],
      ),
    );
  }

  String _calcOvers(int balls) => '${balls ~/ 6}.${balls % 6}';

  Widget _runBtn(int runs, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.tonal(
          onPressed: _isProcessing ? null : () => _runs(runs),
          style: FilledButton.styleFrom(
            backgroundColor: color?.withOpacity(0.1),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('$runs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, VoidCallback onTap, {required Color color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton(
          onPressed: _isProcessing ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCurrentOverTimeline(Innings live) {
    // Current over number (1-based)
    final currentOverNum = (live.legalBalls ~/ 6) + 1;
    final ballsAsync = ref.watch(currentOverBallsProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
      innings: live.inningsNumber,
      overNumber: currentOverNum,
    )));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ballsAsync.when(
        loading: () => const SizedBox(
          height: 36,
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        error: (_, __) => const SizedBox(
          height: 36,
          child: Center(child: Text('Error loading over', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ),
        data: (balls) {
          if (balls.isEmpty) {
            return const SizedBox(
              height: 36,
              child: Center(
                child: Text('New Over - Start Bowling', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
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
                return _ballChip(b);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _ballChip(BallEvent b) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.black87;
    String text = b.shortLabel;

    if (b.isWicket) {
      bg = Colors.red.shade600;
      fg = Colors.white;
    } else if (b.batRuns == 4) {
      bg = Colors.blue.shade600;
      fg = Colors.white;
    } else if (b.batRuns == 6) {
      bg = Colors.purple.shade600;
      fg = Colors.white;
    } else if (b.extraType != ExtraType.none) {
      bg = Colors.orange.shade700;
      fg = Colors.white;
    } else if (b.batRuns > 0) {
      bg = Colors.green.shade600;
      fg = Colors.white;
    }

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: text.length > 2 ? 11 : 13),
      ),
    );
  }
}
