import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/player.dart';
import '../../data/repositories/player_repository.dart';

final playerRepositoryProvider = Provider((ref) => PlayerRepository());

final allPlayersProvider = StreamProvider<List<Player>>((ref) {
  return ref.watch(playerRepositoryProvider).watchAll();
});

final loggedInPlayerProvider = StreamProvider<Player?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return ref.watch(playerRepositoryProvider).watchAll().map((players) {
    if (players.isEmpty) {
      return Player(
        id: user.uid,
        name: user.displayName.isNotEmpty ? user.displayName : 'Player',
        teamId: '',
        role: PlayerRole.allRounder,
        battingStyle: BattingStyle.rightHand,
        bowlingStyle: BowlingStyle.rightArmMedium,
        profilePicUrl: user.photoUrl,
        stats: PlayerStats(),
      );
    }

    // 1. Match by UID
    final byUid = players.where((p) => p.id == user.uid).toList();
    if (byUid.isNotEmpty) return byUid.first;

    // 2. Match by email or phone
    final byContact = players.where((p) =>
      p.phoneNumber != null &&
      p.phoneNumber!.isNotEmpty &&
      (p.phoneNumber == user.email || p.phoneNumber == user.uid)
    ).toList();
    if (byContact.isNotEmpty) return byContact.first;

    // 3. Match by full name
    final userTrimmedName = user.displayName.trim().toLowerCase();
    if (userTrimmedName.isNotEmpty) {
      final byName = players.where((p) =>
        p.name.trim().toLowerCase() == userTrimmedName
      ).toList();
      if (byName.isNotEmpty) return byName.first;

      // 4. Match by first name contains
      final userFirst = userTrimmedName.split(' ').first;
      if (userFirst.length >= 3) {
        final byFirstName = players.where((p) =>
          p.name.trim().toLowerCase().contains(userFirst)
        ).toList();
        if (byFirstName.isNotEmpty) return byFirstName.first;
      }
    }

    // Default: Return fallback Player with AppUser profile info
    return Player(
      id: user.uid,
      name: user.displayName.isNotEmpty ? user.displayName : 'Player',
      teamId: '',
      role: PlayerRole.allRounder,
      battingStyle: BattingStyle.rightHand,
      bowlingStyle: BowlingStyle.rightArmMedium,
      profilePicUrl: user.photoUrl,
      stats: PlayerStats(),
    );
  });
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
