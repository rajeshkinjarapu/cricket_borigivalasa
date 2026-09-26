import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/team.dart';
import '../../data/repositories/team_repository.dart';

final teamRepositoryProvider = Provider((ref) => TeamRepository());

final teamsProvider = StreamProvider<List<Team>>((ref) {
  return ref.watch(teamRepositoryProvider).watchAll().map(
        (teams) => teams.where((t) => !t.isCounty && !t.name.toLowerCase().contains('county')).toList(),
      );
});

final allTeamsProvider = teamsProvider;

final tournamentTeamsProvider = StreamProvider.family<List<Team>, String>((ref, tournamentId) {
  return ref.watch(teamRepositoryProvider).watchByTournament(tournamentId).map(
        (teams) => teams.where((t) => !t.isCounty && !t.name.toLowerCase().contains('county')).toList(),
      );
});

final teamDetailProvider = StreamProvider.family<Team?, String>((ref, id) {
  return ref.watch(teamRepositoryProvider).watchById(id);
});

final teamControllerProvider = StateNotifierProvider<TeamController, AsyncValue<void>>((ref) {
  return TeamController(ref.read(teamRepositoryProvider));
});

class TeamController extends StateNotifier<AsyncValue<void>> {
  TeamController(this._repo) : super(const AsyncValue.data(null));
  final TeamRepository _repo;

  Future<String?> create(Team t) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.create(t);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update(Team t) async {
    state = const AsyncValue.loading();
    try {
      await _repo.update(t);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.delete(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
