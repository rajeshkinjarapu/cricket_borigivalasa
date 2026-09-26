import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/scoring_providers.dart';
import '../../data/models/innings.dart';
import '../../data/models/batting_scorecard.dart';
import '../../data/models/bowling_scorecard.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import 'scorecard_screen.dart';

class LiveViewerScreen extends ConsumerStatefulWidget {
  const LiveViewerScreen({super.key, required this.tournamentId, required this.matchId});
  final String tournamentId, matchId;

  @override
  ConsumerState<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends ConsumerState<LiveViewerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _eventText;
  Color _eventColor = Colors.transparent;
  bool _showEvent = false;

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

  void _showLiveEvent(String text, Color color) {
    setState(() {
      _eventText = text;
      _eventColor = color;
      _showEvent = true;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showEvent = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final i1Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1)));
    final i2Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2)));
    final matchAsync = ref.watch(matchDetailProvider((tournamentId: widget.tournamentId, matchId: widget.matchId)));

    // Listen to innings updates to trigger live events
    ref.listen<AsyncValue<Innings?>>(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1)), (prev, next) {
      _checkForNewBall(prev?.value, next.value);
    });
    ref.listen<AsyncValue<Innings?>>(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2)), (prev, next) {
      _checkForNewBall(prev?.value, next.value);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF), // Deep Blue Professional Theme
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Live Match', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFDE047),
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'LIVE'),
            Tab(text: 'SCORECARD'),
            Tab(text: 'INFO'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: LIVE
              i1Async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (i1) {
                  if (i1 == null) return const Center(child: Text('Match not started yet.'));
                  final match = matchAsync.value;
                  final maxOvers = match?.totalOvers ?? 20;
                  final i2 = i2Async.value;
                  
                  final activeInnings = (i2 != null && i2.legalBalls > 0 || i1.isComplete) ? i2 : i1;
                  if (activeInnings == null) return const SizedBox.shrink();

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1)));
                      ref.invalidate(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2)));
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeroMatchResult(activeInnings, i1, i2, maxOvers),
                        const SizedBox(height: 20),
                        _buildLiveScorecardSection(activeInnings),
                      ],
                    ),
                  );
                },
              ),
              // TAB 2: SCORECARD
              ScorecardScreen(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1, isEmbedded: true),
              // TAB 3: INFO (Placeholder for now)
              const Center(child: Text('Match Info & Squads', style: TextStyle(color: Colors.grey))),
            ],
          ),

          // Live Event Overlay Animation
          if (_showEvent && _eventText != null)
            IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _showEvent ? 1.0 : 0.0,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          decoration: BoxDecoration(
                            color: _eventColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: _eventColor.withOpacity(0.6), blurRadius: 30, spreadRadius: 10),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            _eventText!,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _checkForNewBall(Innings? prev, Innings? curr) {
    if (prev == null || curr == null) return;
    
    // Check if score progressed
    if (curr.legalBalls > prev.legalBalls || curr.runs > prev.runs || curr.wickets > prev.wickets || curr.extras > prev.extras) {
       final rDiff = curr.runs - prev.runs;
       final wDiff = curr.wickets - prev.wickets;
       
       String text;
       Color color;
       
       if (wDiff > 0) {
         text = "WICKET! ❌";
         color = const Color(0xFFDC2626); // Bright Red
       } else if (rDiff == 6) {
         text = "SIX! 🚀";
         color = const Color(0xFF9333EA); // Purple
       } else if (rDiff == 4) {
         text = "FOUR! ⚡";
         color = const Color(0xFFEAB308); // Gold/Yellow
       } else if (rDiff == 0 && curr.extras == prev.extras) {
         text = "DOT BALL •";
         color = const Color(0xFF64748B); // Slate Gray
       } else {
         text = "$rDiff RUN${rDiff > 1 ? 'S' : ''}!";
         color = const Color(0xFF16A34A); // Green
       }
       
       _showLiveEvent(text, color);
    }
  }

  Widget _buildHeroMatchResult(Innings live, Innings i1, Innings? i2, int maxOvers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Top Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${live.inningsNumber == 1 ? "1st" : "2nd"} Innings', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('LIVE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Batting Team
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildPremiumTeamLogo(live.battingTeamName),
                      const SizedBox(height: 12),
                      Text(live.battingTeamName.length > 10 ? live.battingTeamName.substring(0, 10) + '..' : live.battingTeamName, style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('${live.runs}/${live.wickets}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1)),
                      Text('(${live.oversText} ov)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                
                // VS Badge
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: const Center(child: Text('VS', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 14))),
                ),
                
                // Bowling Team
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildPremiumTeamLogo(live.bowlingTeamName ?? 'Opponent'),
                      const SizedBox(height: 12),
                      Text((live.bowlingTeamName ?? 'Opponent').length > 10 ? (live.bowlingTeamName ?? 'Opponent').substring(0, 10) + '..' : (live.bowlingTeamName ?? 'Opponent'), style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(live.inningsNumber == 1 ? 'Yet to bat' : '${i1.runs}/${i1.wickets}', style: TextStyle(fontSize: live.inningsNumber == 1 ? 16 : 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1)),
                      if (live.inningsNumber == 2)
                        Text('(${i1.oversText} ov)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Match Situation Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPremiumStat('CRR', live.runRate.toStringAsFixed(2)),
                if (live.targetRuns != null) ...[
                  _buildPremiumStat('REQ', ((live.targetRuns! - live.runs) / (((maxOvers * 6) - live.legalBalls) / 6)).toStringAsFixed(2)),
                  _buildPremiumStat('TARGET', '${live.targetRuns}'),
                ] else ...[
                  _buildPremiumStat('PROJ', '${live.legalBalls > 0 ? (live.runs / live.legalBalls * maxOvers * 6).round() : 0}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTeamLogo(String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Very Light Blue
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
      ),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'T', style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w900, fontSize: 24))),
    );
  }

  Widget _buildPremiumStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildLiveScorecardSection(Innings live) {
    final k = (tournamentId: widget.tournamentId, matchId: widget.matchId, innings: live.inningsNumber);
    final batRowsAsync = ref.watch(battingScorecardProvider(k));
    final bowlRowsAsync = ref.watch(bowlingScorecardProvider(k));

    final batRows = batRowsAsync.value ?? [];
    final bowlRows = bowlRowsAsync.value ?? [];

    final striker = batRows.where((r) => r.playerId == live.strikerId).firstOrNull;
    final nonStriker = batRows.where((r) => r.playerId == live.nonStrikerId).firstOrNull;
    final bowler = bowlRows.where((r) => r.playerId == live.currentBowlerId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // BATTERS HEADER (Clean Colorful Theme)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF), // Soft Blue Background
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Batter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)))),
                Expanded(child: Center(child: Text('R', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))))),
                Expanded(child: Center(child: Text('B', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))))),
                Expanded(child: Center(child: Text('4s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))))),
                Expanded(child: Center(child: Text('6s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('SR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))))),
              ],
            ),
          ),
          if (striker != null) _buildBatterRow(striker, true),
          if (striker != null && nonStriker != null) const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (nonStriker != null) _buildBatterRow(nonStriker, false),
          if (striker == null && nonStriker == null)
            const Padding(padding: EdgeInsets.all(16), child: Text('Waiting for batsmen...', style: TextStyle(color: Colors.grey))),

          const SizedBox(height: 8),
          
          // BOWLERS HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4), // Soft Green Background
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D)))),
                Expanded(child: Center(child: Text('O', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D))))),
                Expanded(child: Center(child: Text('M', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D))))),
                Expanded(child: Center(child: Text('R', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D))))),
                Expanded(child: Center(child: Text('W', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D))))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D))))),
              ],
            ),
          ),
          if (bowler != null) _buildBowlerRow(bowler),
          if (bowler == null)
            const Padding(padding: EdgeInsets.all(16), child: Text('Waiting for bowler...', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBatterRow(BattingScorecardRow b, bool isStriker) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(b.playerName.split(' ').first, style: TextStyle(fontSize: 14, fontWeight: isStriker ? FontWeight.bold : FontWeight.w600, color: isStriker ? const Color(0xFF0F172A) : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (isStriker) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: Center(child: Text('${b.runs}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))))),
          Expanded(child: Center(child: Text('${b.balls}', style: const TextStyle(fontSize: 14, color: Colors.black87)))),
          Expanded(child: Center(child: Text('${b.fours}', style: const TextStyle(fontSize: 14, color: Colors.black87)))),
          Expanded(child: Center(child: Text('${b.sixes}', style: const TextStyle(fontSize: 14, color: Colors.black87)))),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(((b.runs / (b.balls > 0 ? b.balls : 1)) * 100).toStringAsFixed(1), style: const TextStyle(fontSize: 14, color: Colors.black87)))),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(BowlingScorecardRow b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(b.playerName.split(' ').first, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: Center(child: Text(b.oversText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))))),
          Expanded(child: Center(child: Text('${b.maidens}', style: const TextStyle(fontSize: 14, color: Colors.black87)))),
          Expanded(child: Center(child: Text('${b.runs}', style: const TextStyle(fontSize: 14, color: Colors.black87)))),
          Expanded(child: Center(child: Text('${b.wickets}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))))),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(b.economy.toStringAsFixed(1), style: const TextStyle(fontSize: 14, color: Colors.black87)))),
        ],
      ),
    );
  }
}
