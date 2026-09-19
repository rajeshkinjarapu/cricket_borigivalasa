import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tournament.dart';
import '../../data/repositories/tournament_repository.dart';

import '../../../matches/data/models/match.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../data/models/team_standing.dart';
import '../../../../core/constants/cricket_enums.dart';

final matchRepositoryProvider = Provider((_) => MatchRepository());

final tournamentRepositoryProvider = Provider((_) => TournamentRepository());
final tournamentListProvider = StreamProvider<List<Tournament>>((ref) =>
  ref.watch(tournamentRepositoryProvider).watchAll());
final allTournamentsProvider = tournamentListProvider;
final tournamentDetailProvider = StreamProvider.family<Tournament?, String>(
  (ref, id) => ref.watch(tournamentRepositoryProvider).watchById(id));
  
final tournamentMatchesProvider = StreamProvider.family<List<MatchModel>, String>((ref, id) =>
  ref.watch(matchRepositoryProvider).watchAll(id));

final tournamentStandingsProvider = Provider.family<AsyncValue<List<TeamStanding>>, String>((ref, id) {
  final matches = ref.watch(tournamentMatchesProvider(id));
  return matches.whenData((list) {
    final Map<String, TeamStanding> map = {};
    // Track stats for NRR: runs scored, overs faced, runs conceded, overs bowled
    final Map<String, int> runsScoredMap = {};
    final Map<String, double> oversFacedMap = {};
    final Map<String, int> runsConcededMap = {};
    final Map<String, double> oversBowledMap = {};

    for (final m in list) {
      if (m.status != MatchStatus.completed && m.status != MatchStatus.abandoned) continue;
      
      map.putIfAbsent(m.teamAId, () => TeamStanding(teamId: m.teamAId, teamName: m.teamA));
      map.putIfAbsent(m.teamBId, () => TeamStanding(teamId: m.teamBId, teamName: m.teamB));
      
      var ta = map[m.teamAId]!;
      var tb = map[m.teamBId]!;
      
      ta = ta.copyWith(matchesPlayed: ta.matchesPlayed + 1);
      tb = tb.copyWith(matchesPlayed: tb.matchesPlayed + 1);
      
      if (m.isTie || m.status == MatchStatus.abandoned) {
        ta = ta.copyWith(tied: ta.tied + 1, points: ta.points + 1);
        tb = tb.copyWith(tied: tb.tied + 1, points: tb.points + 1);
      } else if (m.winnerTeamId == m.teamAId) {
        ta = ta.copyWith(won: ta.won + 1, points: ta.points + 2);
        tb = tb.copyWith(lost: tb.lost + 1);
      } else if (m.winnerTeamId == m.teamBId) {
        tb = tb.copyWith(won: tb.won + 1, points: tb.points + 2);
        ta = ta.copyWith(lost: ta.lost + 1);
      }
      
      map[m.teamAId] = ta;
      map[m.teamBId] = tb;

      // NRR calculation from liveScore if available
      if (m.liveScore != null && m.status == MatchStatus.completed) {
        final inn1 = m.liveScore!['inn1'] as Map<String, dynamic>?;
        final inn2 = m.liveScore!['inn2'] as Map<String, dynamic>?;
        if (inn1 != null && inn2 != null) {
          final inn1TeamId = inn1['teamId'] as String?;
          final inn1Runs = (inn1['runs'] as num?)?.toInt() ?? 0;
          final inn1Wkts = (inn1['wickets'] as num?)?.toInt() ?? 0;
          final inn1Balls = (inn1['legalBalls'] as num?)?.toInt() ?? 0;

          final inn2TeamId = inn2['teamId'] as String?;
          final inn2Runs = (inn2['runs'] as num?)?.toInt() ?? 0;
          final inn2Wkts = (inn2['wickets'] as num?)?.toInt() ?? 0;
          final inn2Balls = (inn2['legalBalls'] as num?)?.toInt() ?? 0;

          if (inn1TeamId != null && inn2TeamId != null) {
            final inn1Overs = (inn1Wkts >= 10 || inn1Balls >= m.totalOvers * 6)
                ? m.totalOvers.toDouble()
                : (inn1Balls / 6.0);
            final inn2Overs = (inn2Wkts >= 10 || inn2Balls >= m.totalOvers * 6)
                ? m.totalOvers.toDouble()
                : (inn2Balls / 6.0);

            // Innings 1 batting team
            runsScoredMap[inn1TeamId] = (runsScoredMap[inn1TeamId] ?? 0) + inn1Runs;
            oversFacedMap[inn1TeamId] = (oversFacedMap[inn1TeamId] ?? 0.0) + (inn1Overs > 0 ? inn1Overs : 0.1);
            runsConcededMap[inn1TeamId] = (runsConcededMap[inn1TeamId] ?? 0) + inn2Runs;
            oversBowledMap[inn1TeamId] = (oversBowledMap[inn1TeamId] ?? 0.0) + (inn2Overs > 0 ? inn2Overs : 0.1);

            // Innings 2 batting team
            runsScoredMap[inn2TeamId] = (runsScoredMap[inn2TeamId] ?? 0) + inn2Runs;
            oversFacedMap[inn2TeamId] = (oversFacedMap[inn2TeamId] ?? 0.0) + (inn2Overs > 0 ? inn2Overs : 0.1);
            runsConcededMap[inn2TeamId] = (runsConcededMap[inn2TeamId] ?? 0) + inn1Runs;
            oversBowledMap[inn2TeamId] = (oversBowledMap[inn2TeamId] ?? 0.0) + (inn1Overs > 0 ? inn1Overs : 0.1);
          }
        }
      }
    }

    // Attach calculated NRR
    for (final entry in map.entries) {
      final tid = entry.key;
      final st = entry.value;
      final runsFor = runsScoredMap[tid] ?? 0;
      final ovFor = oversFacedMap[tid] ?? 0.0;
      final runsAgainst = runsConcededMap[tid] ?? 0;
      final ovAgainst = oversBowledMap[tid] ?? 0.0;

      double nrr = 0.0;
      if (ovFor > 0 && ovAgainst > 0) {
        nrr = (runsFor / ovFor) - (runsAgainst / ovAgainst);
      }
      map[tid] = st.copyWith(netRunRate: double.parse(nrr.toStringAsFixed(3)));
    }

    final res = map.values.toList()..sort((a, b) {
      final pt = b.points.compareTo(a.points);
      if (pt != 0) return pt;
      return b.netRunRate.compareTo(a.netRunRate);
    });
    return res;
  });
});

final tournamentControllerProvider = StateNotifierProvider<TournamentController,
  AsyncValue<void>>((ref) => TournamentController(ref.read(tournamentRepositoryProvider)));

class TournamentController extends StateNotifier<AsyncValue<void>> {
  TournamentController(this._r) : super(const AsyncValue.data(null));
  final TournamentRepository _r;
  Future<String?> create(Tournament t) async {
    state = const AsyncValue.loading();
    try { final id = await _r.create(t); state = const AsyncValue.data(null);
      return id; } catch (e, st) { state = AsyncValue.error(e, st); return null; }
  }
  Future<bool> update(Tournament t) async {
    state = const AsyncValue.loading();
    try { await _r.update(t); state = const AsyncValue.data(null); return true; }
    catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }
  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try { await _r.delete(id); state = const AsyncValue.data(null); return true; }
    catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }
}
