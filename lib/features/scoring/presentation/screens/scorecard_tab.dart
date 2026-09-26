import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/innings.dart';
import '../../data/models/batting_scorecard.dart';
import '../../data/models/bowling_scorecard.dart';
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // ── BATTING CARD ──
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('BATTER', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.5))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 10.5))),
                    Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10.5))),
                    Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10.5))),
                    Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10.5))),
                    Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10.5))),
                  ],
                ),
              ),

              batRowsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
                ),
                error: (e, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $e')),
                data: (rows) {
                  if (rows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: Center(child: Text('No batting data available', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12))),
                    );
                  }
                  return Column(
                    children: [
                      ...rows.asMap().entries.map((e) {
                        final i = e.key;
                        final r = e.value;
                        final sr = r.balls > 0 ? (r.runs * 100 / r.balls).toStringAsFixed(1) : '0.0';
                        return Container(
                          color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        color: r.isOut ? const Color(0xFF334155) : const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.runs}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.balls}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.fours}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.sixes}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      sr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              if (r.isOut && r.dismissalText != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    r.dismissalText!,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              if (!r.isOut)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'batting',
                                      style: TextStyle(fontSize: 9, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      // Extras Row
                      Container(
                        color: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 4,
                              child: Text('Extras', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569), fontSize: 11.5)),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                '${innings.extras} (WD ${innings.wides}, NB ${innings.noballs}, B ${innings.byes}, LB ${innings.legbyes})',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Total Row
                      Container(
                        color: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 4,
                              child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 12, letterSpacing: 0.5)),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                '${innings.runs}/${innings.wickets} (${innings.oversText} Overs)',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF1E3A8A)),
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
        
        const SizedBox(height: 8),
        
        // ── BOWLING CARD ──
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('BOWLER', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.5))),
                    Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 10.5))),
                    Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10.5))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10.5))),
                    Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 10.5))),
                    Expanded(flex: 2, child: Text('ECON', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10.5))),
                  ],
                ),
              ),

              bowlRowsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
                ),
                error: (e, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $e')),
                data: (allRows) {
                  final rows = allRows.where((r) => r.balls > 0 || r.wides > 0 || r.noballs > 0).toList();
                  if (rows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: Center(child: Text('No bowlers yet', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12))),
                    );
                  }
                  return Column(
                    children: rows.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value;
                      final econ = r.balls > 0 ? (r.runs * 6 / r.balls).toStringAsFixed(1) : '0.0';
                      final oversText = '${r.balls ~/ 6}.${r.balls % 6}';
                      return Container(
                        color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                r.playerName,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 12.5),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                oversText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 12.5),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${r.maidens}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${r.runs}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${r.wickets}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), fontSize: 12.5),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                econ,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
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
