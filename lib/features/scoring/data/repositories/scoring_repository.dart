import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../players/data/models/player.dart';
import '../../../teams/data/models/team.dart';
import '../../domain/scoring_engine.dart';
import '../models/ball_event.dart';
import '../models/batting_scorecard.dart';
import '../models/bowling_scorecard.dart';
import '../models/innings.dart';

export '../models/batting_scorecard.dart';
export '../models/bowling_scorecard.dart';

class ScoringRepository {
  ScoringRepository({SupabaseClient? s}) : _supabase = s ?? Supabase.instance.client;
  final SupabaseClient _supabase;

  String _innId(String matchId, int inningsNumber) => '${matchId}_$inningsNumber';

  Stream<List<BallEvent>> watchCurrentOverBalls(String t, String m, int n, int overNumber) {
    return _supabase.from('ball_events')
      .stream(primaryKey: ['id'])
      .eq('innings_id', _innId(m, n))
      .eq('over_number', overNumber)
      .map((data) => data.map((d) => BallEvent.fromJson(d)).toList()
        ..sort((a, b) => a.ballNumber.compareTo(b.ballNumber)));
  }

  Stream<Innings?> watchInnings(String t, String m, int n) {
    return _supabase.from('innings')
      .stream(primaryKey: ['id'])
      .eq('id', _innId(m, n))
      .map((data) => data.isNotEmpty ? Innings.fromJson(data.first) : null);
  }

  // To properly support Batting/Bowling Scorecard streaming without a complex view, 
  // we compute it from the ball events stream + innings data
  Stream<List<BattingScorecardRow>> watchBatting(String t, String m, int n) async* {
    final inningsStream = watchInnings(t, m, n);
    final ballsStream = _supabase.from('ball_events')
      .stream(primaryKey: ['id'])
      .eq('innings_id', _innId(m, n))
      .map((data) => data.map((d) => BallEvent.fromJson(d)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
        
    await for (final combo in _combineLatest(inningsStream, ballsStream)) {
      final inn = combo[0] as Innings?;
      final balls = combo[1] as List<BallEvent>;
      if (inn == null) {
        yield [];
        continue;
      }
      final snap = ScoringEngine.reduce(
        openingStrikerId: inn.openingStrikerId,
        openingStrikerName: inn.openingStrikerName,
        openingNonStrikerId: inn.openingNonStrikerId,
        openingNonStrikerName: inn.openingNonStrikerName, 
        balls: balls,
      );
      yield snap.batting.values.toList()..sort((a, b) => a.battingOrder.compareTo(b.battingOrder));
    }
  }

  Stream<List<BowlingScorecardRow>> watchBowling(String t, String m, int n) async* {
    final inningsStream = watchInnings(t, m, n);
    final ballsStream = _supabase.from('ball_events')
      .stream(primaryKey: ['id'])
      .eq('innings_id', _innId(m, n))
      .map((data) => data.map((d) => BallEvent.fromJson(d)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
        
    await for (final combo in _combineLatest(inningsStream, ballsStream)) {
      final inn = combo[0] as Innings?;
      final balls = combo[1] as List<BallEvent>;
      if (inn == null) {
        yield [];
        continue;
      }
      final snap = ScoringEngine.reduce(
        openingStrikerId: inn.openingStrikerId,
        openingStrikerName: inn.openingStrikerName,
        openingNonStrikerId: inn.openingNonStrikerId,
        openingNonStrikerName: inn.openingNonStrikerName, 
        balls: balls,
      );
      final maidens = _computeMaidens(balls);
      yield snap.bowling.entries.map((e) => e.value.copyWith(maidens: maidens[e.key] ?? 0)).toList();
    }
  }

  Stream<List<dynamic>> _combineLatest(Stream<dynamic> a, Stream<dynamic> b) {
    late StreamController<List<dynamic>> controller;
    dynamic lastA, lastB;
    bool hasA = false, hasB = false;
    StreamSubscription? subA, subB;

    controller = StreamController<List<dynamic>>.broadcast(
      onListen: () {
        subA = a.listen((valA) {
          lastA = valA;
          hasA = true;
          if (hasB && !controller.isClosed) controller.add([lastA, lastB]);
        }, onError: controller.addError);

        subB = b.listen((valB) {
          lastB = valB;
          hasB = true;
          if (hasA && !controller.isClosed) controller.add([lastA, lastB]);
        }, onError: controller.addError);
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
      },
    );
    return controller.stream;
  }

  Future<List<BallEvent>> loadAllBalls(String t, String m, int n) async {
    final data = await _supabase.from('ball_events')
        .select()
        .eq('innings_id', _innId(m, n))
        .order('ball_time');
    return data.map((d) => BallEvent.fromJson(d)).toList();
  }

  Future<void> initInnings({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Team battingTeam, required Team bowlingTeam,
      required Player openingStriker, required Player openingNonStriker,
      required Player openingBowler, int? targetRuns}) async {
    
    final innData = {
      'id': _innId(matchId, inningsNumber),
      'match_id': matchId,
      'tournament_id': tournamentId,
      'innings_number': inningsNumber,
      'batting_team_id': battingTeam.id,
      'bowling_team_id': bowlingTeam.id,
      'runs': 0, 'wickets': 0, 'legal_balls': 0,
      'target_runs': targetRuns, 'is_complete': false,
      'current_striker_id': openingStriker.id,
      'current_non_striker_id': openingNonStriker.id,
      'current_bowler_id': openingBowler.id,
      'created_at': DateTime.now().toIso8601String()
    };
    
    await _supabase.from('innings').insert(innData);
    
    // Set match status to live
    await _supabase.from('matches').update({
      'status': 'live',
      'started_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  Future<void> recordBall({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Innings innings, required BallEvent ball,
      required int maxOvers, required int playersPerSide}) async {
    
    // Insert the ball event
    final ballData = ball.toJson();
    final ballId = const Uuid().v4();
    ballData['id'] = ballId;
    ballData['match_id'] = matchId;
    ballData['innings_id'] = _innId(matchId, inningsNumber);
    ballData['over_number'] = innings.legalBalls ~/ 6;
    ballData['ball_number'] = (innings.legalBalls % 6) + 1;
    
    // Calculate new runs
    final allBalls = await loadAllBalls(tournamentId, matchId, inningsNumber);
    allBalls.add(BallEvent.fromJson(ballData));
    
    final snap = ScoringEngine.reduce(
      openingStrikerId: innings.openingStrikerId,
      openingStrikerName: innings.openingStrikerName,
      openingNonStrikerId: innings.openingNonStrikerId,
      openingNonStrikerName: innings.openingNonStrikerName, 
      balls: allBalls
    );
    
    final complete = ScoringEngine.checkInningsComplete(snap: snap,
      maxOvers: maxOvers, playersPerSide: playersPerSide,
      targetRuns: innings.targetRuns);
      
    await Future.wait([
      _supabase.from('ball_events').insert(ballData),
      _supabase.from('innings').update({
        'runs': snap.runs, 'wickets': snap.wickets, 'legal_balls': snap.legalBalls,
        'current_striker_id': snap.strikerId,
        'current_non_striker_id': snap.nonStrikerId,
        'current_bowler_id': ball.bowlerId,
        'is_complete': complete != null,
      }).eq('id', _innId(matchId, inningsNumber))
    ]);

    if (complete != null && inningsNumber == 2) {
       await finalizeMatch(tournamentId: tournamentId, matchId: matchId, maxOvers: maxOvers, playersPerSide: playersPerSide);
    }
  }

  Future<void> finalizeMatch({
    required String tournamentId,
    required String matchId,
    int? maxOvers,
    int playersPerSide = 11,
  }) async {
    // simplified finalize
    await _supabase.from('matches').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String()
    }).eq('id', matchId);
  }

  Future<void> undoLastBall({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Innings innings, required int maxOvers,
      required int playersPerSide}) async {
    // get last ball
    final balls = await loadAllBalls(tournamentId, matchId, inningsNumber);
    if (balls.isEmpty) return;
    
    final lastBall = balls.last;
    if (lastBall.id != null) {
      await _supabase.from('ball_events').delete().eq('id', lastBall.id!);
    }
    
    balls.removeLast();
    
    final snap = ScoringEngine.reduce(
      openingStrikerId: innings.openingStrikerId,
      openingStrikerName: innings.openingStrikerName,
      openingNonStrikerId: innings.openingNonStrikerId,
      openingNonStrikerName: innings.openingNonStrikerName, 
      balls: balls
    );
    
    await _supabase.from('innings').update({
        'runs': snap.runs, 'wickets': snap.wickets, 'legal_balls': snap.legalBalls,
        'current_striker_id': snap.strikerId,
        'current_non_striker_id': snap.nonStrikerId,
        'is_complete': false,
    }).eq('id', _innId(matchId, inningsNumber));
  }

  Future<void> setCurrentBowler({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Player bowler}) async {
    await _supabase.from('innings').update({
      'current_bowler_id': bowler.id,
    }).eq('id', _innId(matchId, inningsNumber));
  }

  Future<void> swapStrike({
    required String tournamentId,
    required String matchId,
    required int inningsNumber,
    required Innings innings,
  }) async {
    if (innings.strikerId == null || innings.nonStrikerId == null) return;
    await _supabase.from('innings').update({
      'current_striker_id': innings.nonStrikerId,
      'current_non_striker_id': innings.strikerId,
    }).eq('id', _innId(matchId, inningsNumber));
  }

  Map<String, int> _computeMaidens(List<BallEvent> balls) {
    final overBalls = <String, Map<int, List<BallEvent>>>{};
    for (final b in balls) {
      overBalls.putIfAbsent(b.bowlerId, () => {}).putIfAbsent(b.overNumber, () => []).add(b);
    }
    final maidens = <String, int>{};
    for (final bowlerEntry in overBalls.entries) {
      int count = 0;
      for (final overList in bowlerEntry.value.values) {
        final legalCount = overList.where((b) => b.isLegalDelivery).length;
        if (legalCount >= 6) {
          final runs = overList.fold<int>(0, (sum, b) => sum + b.bowlerRunsConceded);
          if (runs == 0) count++;
        }
      }
      maidens[bowlerEntry.key] = count;
    }
    return maidens;
  }
}
