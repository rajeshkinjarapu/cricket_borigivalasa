import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/innings.dart';
import '../providers/scoring_providers.dart';

class ScorecardTab extends ConsumerWidget {
  const ScorecardTab({super.key, required this.tournamentId, required this.matchId, required this.innings});
  
  final String tournamentId;
  final String matchId;
  final Innings innings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tournamentId: tournamentId, matchId: matchId, innings: innings.inningsNumber);
    final batRowsAsync = ref.watch(battingScorecardProvider(key));
    final bowlRowsAsync = ref.watch(bowlingScorecardProvider(key));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Batting Table
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('Batsman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              batRowsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
                data: (rows) {
                  return Column(
                    children: [
                      ...rows.asMap().entries.map((e) {
                        final i = e.key;
                        final r = e.value;
                        final sr = r.balls > 0 ? (r.runs * 100 / r.balls).toStringAsFixed(1) : '0.0';
                        return Container(
                          color: i.isEven ? Colors.white : Colors.grey.shade50,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      r.playerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: r.isOut ? Colors.black87 : Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Text('${r.runs}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(child: Text('${r.balls}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
                                  Expanded(child: Text('${r.fours}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
                                  Expanded(child: Text('${r.sixes}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
                                  Expanded(flex: 2, child: Text(sr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
                                ],
                              ),
                              if (r.isOut && r.dismissalText != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    r.dismissalText!,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              if (!r.isOut)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text('not out', style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic)),
                                ),
                            ],
                          ),
                        );
                      }),
                      // Extras and Total Row
                      Container(
                        color: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(flex: 4, child: Text('Extras', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(
                              flex: 5,
                              child: Text(
                                '${innings.extras} (WD ${innings.wides}, NB ${innings.noballs}, B ${innings.byes}, LB ${innings.legbyes})',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(flex: 4, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(
                              flex: 5,
                              child: Text(
                                '${innings.runs}/${innings.wickets} (${innings.oversText} Overs)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Bowling Table
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('Bowler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('ECON', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              bowlRowsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
                data: (allRows) {
                  final rows = allRows.where((r) => r.balls > 0 || r.wides > 0 || r.noballs > 0).toList();
                  if (rows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No bowlers yet', style: TextStyle(color: Colors.black54))),
                    );
                  }
                  return Column(
                    children: rows.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value;
                      final econ = r.balls > 0 ? (r.runs * 6 / r.balls).toStringAsFixed(1) : '0.0';
                      final oversText = '${r.balls ~/ 6}.${r.balls % 6}';
                      return Container(
                        color: i.isEven ? Colors.white : Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(flex: 4, child: Text(r.playerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                            Expanded(child: Text(oversText, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('${r.maidens}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
                            Expanded(child: Text('${r.runs}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
                            Expanded(child: Text('${r.wickets}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                            Expanded(flex: 2, child: Text(econ, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
