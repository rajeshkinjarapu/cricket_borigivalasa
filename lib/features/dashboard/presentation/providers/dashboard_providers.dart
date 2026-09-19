import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tournaments/data/repositories/tournament_repository.dart';
import '../../../tournaments/data/models/tournament.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../../matches/data/models/match.dart';

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

// ── Dashboard Stats Providers ──
final _db = FirebaseFirestore.instance;

final totalTeamsCountProvider = StreamProvider<int>((ref) {
  return _db
      .collectionGroup('teams')
      .snapshots()
      .map((snap) => snap.docs.length);
});

final totalPlayersCountProvider = StreamProvider<int>((ref) {
  return _db
      .collectionGroup('players')
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
