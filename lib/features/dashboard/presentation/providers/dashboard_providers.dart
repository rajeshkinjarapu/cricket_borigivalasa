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

final liveMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(matchRepositoryProvider).getLiveMatches();
});

final upcomingMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(matchRepositoryProvider).getUpcomingMatches();
});
