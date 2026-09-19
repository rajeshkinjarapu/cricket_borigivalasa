import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player.dart';
import '../../data/repositories/player_repository.dart';

final playerRepositoryProvider = Provider((ref) => PlayerRepository());

final allPlayersProvider = StreamProvider<List<Player>>((ref) {
  return ref.watch(playerRepositoryProvider).watchAll();
});

final teamPlayersProvider = StreamProvider.family<List<Player>, String>((ref, teamId) {
  return ref.watch(playerRepositoryProvider).watchByTeam(teamId);
});

final playerDetailProvider = StreamProvider.family<Player?, String>((ref, id) {
  return ref.watch(playerRepositoryProvider).watchById(id);
});

final playerControllerProvider = StateNotifierProvider<PlayerController, AsyncValue<void>>((ref) {
  return PlayerController(ref.read(playerRepositoryProvider));
});

class PlayerController extends StateNotifier<AsyncValue<void>> {
  PlayerController(this._repo) : super(const AsyncValue.data(null));
  final PlayerRepository _repo;

  Future<String?> create(Player p) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.create(p);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update(Player p) async {
    state = const AsyncValue.loading();
    try {
      await _repo.update(p);
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
