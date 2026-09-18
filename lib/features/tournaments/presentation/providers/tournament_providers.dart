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
final tournamentDetailProvider = StreamProvider.family<Tournament?, String>(
  (ref, id) => ref.watch(tournamentRepositoryProvider).watchById(id));
  
final tournamentMatchesProvider = StreamProvider.family<List<MatchModel>, String>((ref, id) =>
  ref.watch(matchRepositoryProvider).watchAll(id));

final tournamentStandingsProvider = Provider.family<AsyncValue<List<TeamStanding>>, String>((ref, id) {
  final matches = ref.watch(tournamentMatchesProvider(id));
  return matches.whenData((list) {
    final Map<String, TeamStanding> map = {};
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
    }
    final res = map.values.toList()..sort((a, b) => b.points.compareTo(a.points));
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
