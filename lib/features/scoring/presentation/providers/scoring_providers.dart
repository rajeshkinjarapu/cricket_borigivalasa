import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../tournaments/presentation/providers/tournament_providers.dart';
import '../../data/models/ball_event.dart';
import '../../data/models/innings.dart';
import '../../data/repositories/scoring_repository.dart';

final scoringRepositoryProvider = Provider((_) => ScoringRepository());
typedef InningsKey = ({String tournamentId, String matchId, int innings});
final inningsProvider = StreamProvider.family<Innings?, InningsKey>(
  (ref, k) => ref.watch(scoringRepositoryProvider)
    .watchInnings(k.tournamentId, k.matchId, k.innings));
final battingScorecardProvider = StreamProvider.family<List<BattingScorecardRow>, InningsKey>(
  (ref, k) => ref.watch(scoringRepositoryProvider)
    .watchBatting(k.tournamentId, k.matchId, k.innings));
final bowlingScorecardProvider = StreamProvider.family<List<BowlingScorecardRow>, InningsKey>(
  (ref, k) => ref.watch(scoringRepositoryProvider)
    .watchBowling(k.tournamentId, k.matchId, k.innings));
final allBallsProvider = FutureProvider.family<List<BallEvent>, InningsKey>(
  (ref, k) => ref.watch(scoringRepositoryProvider)
    .loadAllBalls(k.tournamentId, k.matchId, k.innings));
final maxOversProvider = Provider.family<int, String>((ref, t) {
  final tr = ref.watch(tournamentDetailProvider(t)).value;
  return tr?.format.maxOvers ?? 20;
});
const playersPerSide = 11;
