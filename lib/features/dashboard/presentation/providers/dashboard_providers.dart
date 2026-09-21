import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tournaments/data/repositories/tournament_repository.dart';
import '../../../tournaments/data/models/tournament.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../../matches/data/models/match.dart';
import '../../../players/data/models/player.dart';
import '../../../members/presentation/providers/member_providers.dart';
import '../../../players/presentation/providers/player_providers.dart';

final tournamentRepositoryProvider = Provider((ref) => TournamentRepository());
final matchRepositoryProvider = Provider((ref) => MatchRepository());

final activeTournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).getActiveTournaments();
});

final allTournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).getAllTournaments();
});

final liveMatchesProvider = StreamProvider<List<Match>>((ref) {
  return ref.watch(matchRepositoryProvider).getLiveMatches();
});

final upcomingMatchesProvider = StreamProvider<List<Match>>((ref) {
  return ref.watch(matchRepositoryProvider).getUpcomingMatches();
});

final allMatchesProvider = StreamProvider<List<Match>>((ref) {
  return ref.watch(matchRepositoryProvider).getAllMatches();
});

// Recent notifications provider for hero banner
final recentNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final _db = FirebaseFirestore.instance;
  return _db
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(3)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  });
});

final _db = FirebaseFirestore.instance;

final totalTeamsCountProvider = StreamProvider<int>((ref) {
  return _db
      .collection('teams')
      .snapshots()
      .map((snap) => snap.docs.length);
});

final totalUnifiedMembersCountProvider = Provider<AsyncValue<int>>((ref) {
  final usersAsync = ref.watch(memberListProvider);
  final playersAsync = ref.watch(allPlayersProvider);

  if (usersAsync.isLoading || playersAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (usersAsync.hasError) {
    return AsyncValue.error(usersAsync.error!, usersAsync.stackTrace!);
  }

  final users = usersAsync.value ?? [];
  final players = playersAsync.value ?? [];

  final Set<String> processedPlayerIds = {};
  final Set<String> processedPhones = {};
  final Set<String> processedNames = {};

  int count = 0;

  for (final u in users) {
    count++;
    String contact = u.email;
    if (u.email.endsWith('@member.cricket.com')) {
      contact = u.email.replaceAll('@member.cricket.com', '');
      processedPhones.add(contact);
    }
    if (u.displayName.isNotEmpty) {
      processedNames.add(u.displayName.toLowerCase().trim());
    }

    for (final p in players) {
      if ((p.phoneNumber != null && p.phoneNumber == contact) ||
          p.id == u.uid ||
          p.name.toLowerCase().trim() == u.displayName.toLowerCase().trim()) {
        processedPlayerIds.add(p.id);
        break;
      }
    }
  }

  for (final p in players) {
    if (processedPlayerIds.contains(p.id)) continue;
    if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty && processedPhones.contains(p.phoneNumber)) continue;
    if (processedNames.contains(p.name.toLowerCase().trim())) continue;

    count++;
  }

  return AsyncValue.data(count);
});

final totalPlayersCountProvider = StreamProvider<int>((ref) {
  return _db
      .collection('players')
      .snapshots()
      .map((snap) => snap.docs.length);
});

final totalTournamentsCountProvider = StreamProvider<int>((ref) {
  return _db
      .collection('tournaments')
      .snapshots()
      .map((snap) => snap.docs.length);
});

final totalMatchesCountProvider = StreamProvider<int>((ref) {
  return _db
      .collectionGroup('matches')
      .snapshots()
      .map((snap) => snap.docs.length);
});

final activeMatchesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(liveMatchesProvider.stream).map((list) => list.length);
});

// ── Leaderboard Providers ──
final _playersRef = FirebaseFirestore.instance.collection('players');

/// Top batters by runs scored
final battingLeaderboardProvider = StreamProvider<List<Player>>((ref) {
  return _playersRef.snapshots().map((snap) {
    final players = snap.docs
        .map((d) => Player.fromJson({...d.data(), 'id': d.id}))
        .where((p) => p.stats.runsScored > 0)
        .toList();
    players.sort((a, b) => b.stats.runsScored.compareTo(a.stats.runsScored));
    return players.take(10).toList();
  });
});

/// Top bowlers by wickets taken
final bowlingLeaderboardProvider = StreamProvider<List<Player>>((ref) {
  return _playersRef.snapshots().map((snap) {
    final players = snap.docs
        .map((d) => Player.fromJson({...d.data(), 'id': d.id}))
        .where((p) => p.stats.wicketsTaken > 0)
        .toList();
    players.sort((a, b) => b.stats.wicketsTaken.compareTo(a.stats.wicketsTaken));
    return players.take(10).toList();
  });
});

/// All players sorted by composite score: runs + wickets*20
final overallLeaderboardProvider = StreamProvider<List<Player>>((ref) {
  return _playersRef.snapshots().map((snap) {
    final players = snap.docs
        .map((d) => Player.fromJson({...d.data(), 'id': d.id}))
        .toList();
    players.sort((a, b) {
      final scoreA = a.stats.runsScored + (a.stats.wicketsTaken * 20);
      final scoreB = b.stats.runsScored + (b.stats.wicketsTaken * 20);
      return scoreB.compareTo(scoreA);
    });
    return players.take(10).toList();
  });
});
