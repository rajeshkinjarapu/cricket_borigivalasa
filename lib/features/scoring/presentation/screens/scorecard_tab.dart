import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../matches/data/models/match.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../data/models/innings.dart';
import '../../data/models/batting_scorecard.dart';
import '../../data/models/bowling_scorecard.dart';
import '../providers/scoring_providers.dart';

class ScorecardTab extends ConsumerWidget {
  const ScorecardTab({
    super.key,
    required this.tournamentId,
    required this.matchId,
    required this.innings,
    this.match,
  });
  
  final String tournamentId;
  final String matchId;
  final Innings innings;
  final MatchModel? match;

  String _resolveBatterName({
    required String playerId,
    required String rawName,
    required List<Player> players,
    required List<Team> teams,
    required int index,
  }) {
    if (rawName.trim().isNotEmpty && rawName != 'Unknown' && rawName != 'Player') {
      return rawName;
    }
    final p = players.where((p) => p.id == playerId).firstOrNull;
    if (p != null && p.name.trim().isNotEmpty) return p.name;

    if (match != null) {
      if (playerId == match!.teamAId || (index == 0 && innings.inningsNumber == 1)) return match!.teamA;
      if (playerId == match!.teamBId || (index == 0 && innings.inningsNumber == 2)) return match!.teamB;
    }

    final t = teams.where((t) => t.id == playerId).firstOrNull;
    if (t != null && t.name.trim().isNotEmpty) return t.name;

    if (match != null && innings.inningsNumber == 1 && match!.teamA.isNotEmpty) {
      return match!.teamA;
    }
    return rawName.trim().isNotEmpty ? rawName : 'Batter ${index + 1}';
  }

  String _resolveBowlerName({
    required String bowlerId,
    required String rawName,
    required List<Player> players,
    required List<Team> teams,
    required int index,
  }) {
    if (rawName.trim().isNotEmpty && rawName != 'Unknown' && rawName != 'Player') {
      return rawName;
    }
    final p = players.where((p) => p.id == bowlerId).firstOrNull;
    if (p != null && p.name.trim().isNotEmpty) return p.name;

    if (match != null) {
      if (bowlerId == match!.teamBId || (innings.inningsNumber == 1)) return match!.teamB;
      if (bowlerId == match!.teamAId || (innings.inningsNumber == 2)) return match!.teamA;
    }

    final t = teams.where((t) => t.id == bowlerId).firstOrNull;
    if (t != null && t.name.trim().isNotEmpty) return t.name;

    if (match != null && innings.inningsNumber == 1 && match!.teamB.isNotEmpty) {
      return match!.teamB;
    }
    return rawName.trim().isNotEmpty ? rawName : 'Bowler ${index + 1}';
  }

  String? _findPlayerPhoto(String playerId, List<Player> players, List<Team> teams) {
    final p = players.where((p) => p.id == playerId).firstOrNull;
    if (p?.profilePicUrl != null && p!.profilePicUrl!.isNotEmpty) return p.profilePicUrl;
    final t = teams.where((t) => t.id == playerId).firstOrNull;
    if (t?.logoUrl != null && t!.logoUrl!.isNotEmpty) return t.logoUrl;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tournamentId: tournamentId, matchId: matchId, innings: innings.inningsNumber);
    final batRowsAsync = ref.watch(battingScorecardProvider(key));
    final bowlRowsAsync = ref.watch(bowlingScorecardProvider(key));
    final allPlayers = ref.watch(allPlayersProvider).value ?? [];
    final allTeams = ref.watch(allTeamsProvider).value ?? [];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        // ── BATTING CARD ──
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 5, child: Text('BATTER', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 11))),
                    Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11))),
                    Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11))),
                    Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11))),
                    Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11))),
                  ],
                ),
              ),

              batRowsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
                ),
                error: (e, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $e')),
                data: (allRows) {
                  // Filter out rows that never faced a ball if other active batsmen exist
                  final validRows = allRows.where((r) => r.balls > 0 || r.runs > 0 || r.isOut).toList();
                  final rows = validRows.isNotEmpty ? validRows : allRows;

                  if (rows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No batting data available', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12))),
                    );
                  }
                  return Column(
                    children: [
                      ...rows.asMap().entries.map((e) {
                        final i = e.key;
                        final r = e.value;
                        final sr = r.balls > 0 ? (r.runs * 100 / r.balls).toStringAsFixed(1) : '0.0';
                        final playerName = _resolveBatterName(
                          playerId: r.playerId,
                          rawName: r.playerName,
                          players: allPlayers,
                          teams: allTeams,
                          index: i,
                        );
                        final photoUrl = _findPlayerPhoto(r.playerId, allPlayers, allTeams);

                        return Container(
                          color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Player Avatar + Name
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: const Color(0xFFDBEAFE),
                                          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: (photoUrl == null || photoUrl.isEmpty)
                                              ? Text(
                                                  playerName.isNotEmpty ? playerName[0].toUpperCase() : 'B',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            playerName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: r.isOut ? const Color(0xFF334155) : const Color(0xFF1E3A8A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.runs}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.balls}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.fours}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.sixes}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      sr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              if (r.isOut && r.dismissalText != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, top: 3),
                                  child: Text(
                                    r.dismissalText!,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              if (!r.isOut)
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, top: 3),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'batting',
                                      style: TextStyle(fontSize: 9.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w800),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 5,
                              child: Text('Extras', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(
                                '${innings.extras} (WD ${innings.wides}, NB ${innings.noballs}, B ${innings.byes}, LB ${innings.legbyes})',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Total Row
                      Container(
                        color: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 5,
                              child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 13, letterSpacing: 0.5)),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(
                                '${innings.runs}/${innings.wickets} (${innings.oversText} Overs)',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF1E3A8A)),
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
        
        const SizedBox(height: 12),
        
        // ── BOWLING CARD ──
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 5, child: Text('BOWLER', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5))),
                    Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 11))),
                    Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11))),
                    Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 11))),
                    Expanded(flex: 2, child: Text('ECON', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11))),
                  ],
                ),
              ),

              bowlRowsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
                ),
                error: (e, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $e')),
                data: (allRows) {
                  final validRows = allRows.where((r) => r.balls > 0 || r.wides > 0 || r.noballs > 0 || r.runs > 0 || r.wickets > 0).toList();
                  final rows = validRows.isNotEmpty ? validRows : allRows;

                  if (rows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No bowlers yet', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12))),
                    );
                  }
                  return Column(
                    children: rows.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value;
                      final econ = r.balls > 0 ? (r.runs * 6 / r.balls).toStringAsFixed(1) : '0.0';
                      final oversText = '${r.balls ~/ 6}.${r.balls % 6}';
                      final bowlerName = _resolveBowlerName(
                        bowlerId: r.playerId,
                        rawName: r.playerName,
                        players: allPlayers,
                        teams: allTeams,
                        index: i,
                      );
                      final photoUrl = _findPlayerPhoto(r.playerId, allPlayers, allTeams);

                      return Container(
                        color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            // Bowler Avatar + Name
                            Expanded(
                              flex: 5,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFFFCE7F3),
                                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: (photoUrl == null || photoUrl.isEmpty)
                                        ? Text(
                                            bowlerName.isNotEmpty ? bowlerName[0].toUpperCase() : 'B',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFBE185D)),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      bowlerName,
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                oversText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13),
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
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), fontSize: 13.5),
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
