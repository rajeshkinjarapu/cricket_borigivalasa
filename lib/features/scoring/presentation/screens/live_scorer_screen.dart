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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Live Scorer', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: i1.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (inn1) {
          if (inn1 == null) {
            return InningsSetupScreen(tournamentId: tournamentId, matchId: matchId, inningsNumber: 1);
          }
          if (inn1.isComplete) {
            return i2.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
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
      ),
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

    return SafeArea(
      child: Column(
        children: [
          // 1. TOP SCOREBOARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Text(live.battingTeamName, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${live.runs}-${live.wickets}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('(${live.oversText})', style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('CRR: ${live.runRate.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    if (live.targetRuns != null)
                      Text('Target: ${live.targetRuns}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // 2. MIDDLE AREA (BATSMEN & BOWLER)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _buildBatterCard(striker, isStriker: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildBatterCard(nonStriker, isStriker: false)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBowlerCard(currentBowler),
                const SizedBox(height: 24),
                const Text('Current Over', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                _buildCurrentOverTimeline(live),
              ],
            ),
          ),

          // 3. SCORING KEYPAD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _runBtn(0), _runBtn(1), _runBtn(2), _runBtn(3), _runBtn(4, color: Colors.blue.shade600), _runBtn(6, color: Colors.indigo),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _actionBtn('WD', _wide, color: Colors.orange.shade700),
                    _actionBtn('NB', _noball, color: Colors.orange.shade700),
                    _actionBtn('BYE', () => _byes(isLegBye: false), color: Colors.grey.shade600),
                    _actionBtn('LB', () => _byes(isLegBye: true), color: Colors.grey.shade600),
                    _actionBtn('OUT', _wicket, color: Colors.red.shade700),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _undoLastBall,
                        icon: const Icon(Icons.undo),
                        label: const Text('UNDO'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                          side: const BorderSide(color: Colors.deepOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _buildBatterCard(BattingScorecardRow? batter, {required bool isStriker}) {
    return Card(
      elevation: 0,
      color: isStriker ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isStriker ? Colors.blue.shade300 : Colors.grey.shade300, width: isStriker ? 2 : 1),
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
                    batter?.playerName ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isStriker ? Colors.blue.shade900 : Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isStriker) const Icon(Icons.star, color: Colors.orange, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${batter?.runs ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('(${batter?.balls ?? 0})', style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 4),
            Text('4s: ${batter?.fours ?? 0}  6s: ${batter?.sixes ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
