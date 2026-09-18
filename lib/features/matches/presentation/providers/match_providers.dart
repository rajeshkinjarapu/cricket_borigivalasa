import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../data/models/match.dart';
import '../../data/repositories/match_repository.dart';

final matchRepositoryProvider = Provider((_) => MatchRepository());

final matchListProvider = StreamProvider.family<List<Match>, String>(
  (ref, t) => ref.watch(matchRepositoryProvider).watchAll(t),
);

typedef MatchKey = ({String tournamentId, String matchId});

final matchDetailProvider = StreamProvider.family<Match?, dynamic>((ref, k) {
  final repo = ref.watch(matchRepositoryProvider);
  if (k is MatchKey) {
    return repo.watchById(k.tournamentId, k.matchId);
  }
  if (k is ({String tournamentId, String matchId})) {
    return repo.watchById(k.tournamentId, k.matchId);
  }
  if (k is String) {
    // If only matchId is passed, watch via collectionGroup
    return repo.getLiveMatches().map((list) =>
        list.where((m) => m.id == k).firstOrNull);
  }
  return Stream.value(null);
});

final tournamentMatchesProvider = StreamProvider.family<List<Match>, String>(
  (ref, t) => ref.watch(matchRepositoryProvider).watchAll(t),
);

final matchControllerProvider = StateNotifierProvider<MatchController, AsyncValue<void>>(
  (ref) => MatchController(ref.read(matchRepositoryProvider)),
);

class MatchController extends StateNotifier<AsyncValue<void>> {
  MatchController(this._r) : super(const AsyncValue.data(null));
  final MatchRepository _r;

  Future<String?> create(dynamic a, [dynamic b]) async {
    state = const AsyncValue.loading();
    try {
      String t;
      Match m;
      if (a is String && b is Match) {
        t = a;
        m = b;
      } else if (a is Match) {
        m = a;
        t = (b is String) ? b : m.tournamentId;
      } else {
        throw ArgumentError('Invalid arguments to create');
      }
      final id = await _r.create(t, m);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> update(dynamic a, [dynamic b]) async {
    state = const AsyncValue.loading();
    try {
      String t;
      Match m;
      if (a is String && b is Match) {
        t = a;
        m = b;
      } else if (a is Match) {
        m = a;
        t = (b is String) ? b : m.tournamentId;
      } else {
        throw ArgumentError('Invalid arguments to update');
      }
      await _r.update(t, m);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String t, String id) async {
    state = const AsyncValue.loading();
    try {
      await _r.delete(t, id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setToss({
    required String tournamentId,
    required String matchId,
    required String tossWinnerTeamId,
    required TossDecision tossDecision,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _r.setToss(
        tournamentId: tournamentId,
        matchId: matchId,
        tossWinnerTeamId: tossWinnerTeamId,
        tossDecision: tossDecision,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> completeMatch({
    required String tournamentId,
    required String matchId,
    required String? winnerTeamId,
    required String resultText,
    bool isTie = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _r.completeMatch(
        tournamentId: tournamentId,
        matchId: matchId,
        winnerTeamId: winnerTeamId,
        resultText: resultText,
        isTie: isTie,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> revertToScheduled({
    required String tournamentId,
    required String matchId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _r.revertToScheduled(tournamentId: tournamentId, matchId: matchId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
