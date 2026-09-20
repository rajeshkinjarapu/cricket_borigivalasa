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

class _MatchSummaryScreenState extends ConsumerState<MatchSummaryScreen> with SingleTickerProviderStateMixin {
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
    final matchAsync = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    )));
    final i1Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1)));
    final i2Async = ref.watch(inningsProvider((tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2)));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Match Center', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (match) {
          if (match == null) return const Center(child: Text('Match not found'));

          final i1 = i1Async.value;
          final i2 = i2Async.value;

          return Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${match.venue} • ${DateFormat('MMM dd, yyyy').format(match.matchDate)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  match.teamA.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(match.teamA, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              _scoreText(match.teamAId, i1, i2),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          child: Text('VS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  match.teamB.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(match.teamB, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              _scoreText(match.teamBId, i1, i2),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Result Banner
                    if (match.status.name == 'completed' || (i2 != null && i2.isComplete))
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getMatchResult(match.teamA, match.teamB, match.teamAId, match.teamBId, i1, i2),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),

              // TABS
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'INFO'),
                    Tab(text: 'SCORECARD 1'),
                    Tab(text: 'SCORECARD 2'),
                  ],
                ),
              ),

              // TAB VIEWS
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // INFO TAB
                    _InfoTab(match: match, i1: i1, i2: i2),
                    
                    // SCORECARD 1
                    i1 != null
                        ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i1)
                        : const Center(child: Text('1st Innings has not started yet')),

                    // SCORECARD 2
                    i2 != null
                        ? ScorecardTab(tournamentId: widget.tournamentId, matchId: widget.matchId, innings: i2)
                        : const Center(child: Text('2nd Innings has not started yet')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scoreText(String teamId, Innings? i1, Innings? i2) {
    Innings? teamInn;
    if (i1?.battingTeamId == teamId) teamInn = i1;
    if (i2?.battingTeamId == teamId) teamInn = i2;

    if (teamInn == null) return const Text('Yet to bat', style: TextStyle(color: Colors.white70, fontSize: 12));
    return Text(
      '${teamInn.runs}/${teamInn.wickets} (${teamInn.oversText})',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  String _getMatchResult(String teamAName, String teamBName, String teamAId, String teamBId, Innings? i1, Innings? i2) {
    if (i1 == null || i2 == null || !i2.isComplete) return 'Match in progress...';
    
    final i1Team = i1.battingTeamId == teamAId ? teamAName : teamBName;
    final i2Team = i2.battingTeamId == teamAId ? teamAName : teamBName;

    if (i2.runs > i1.runs) {
      return '$i2Team won by ${10 - i2.wickets} wickets';
    } else if (i1.runs > i2.runs) {
      return '$i1Team won by ${i1.runs - i2.runs} runs';
    } else {
      return 'Match Tied';
    }
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.match, this.i1, this.i2});
  final MatchModel match;
  final Innings? i1;
  final Innings? i2;

  @override
  Widget build(BuildContext context) {
    final tossWinner = match.tossWinnerId == match.teamAId ? match.teamA : match.teamB;
    final tossDecisionStr = match.tossDecision?.name.toUpperCase() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MATCH INFO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1)),
                const Divider(height: 24),
                _infoRow('Match', '${match.teamA} vs ${match.teamB}'),
                _infoRow('Date', DateFormat('EEEE, MMM dd, yyyy - hh:mm a').format(match.matchDate)),
                _infoRow('Toss', '$tossWinner won the toss and chose to $tossDecisionStr'),
                _infoRow('Venue', match.venue),
                _infoRow('Overs', '${match.totalOvers}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
          Expanded(flex: 7, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
        ],
      ),
    );
  }
}
