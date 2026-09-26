import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../players/data/models/player.dart';
import '../../../teams/data/models/team.dart';
import '../../../matches/data/models/match.dart';
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
      final activeStrikerId = inn.strikerId ?? snap.strikerId;
      final activeNonStrikerId = inn.nonStrikerId ?? snap.nonStrikerId;
      final list = snap.batting.values.map((row) {
        return row.copyWith(
          isStriker: row.playerId == activeStrikerId,
          isNonStriker: row.playerId == activeNonStrikerId,
        );
      }).toList()..sort((a, b) => a.battingOrder.compareTo(b.battingOrder));
      yield list;
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
      required Player openingStriker, Player? openingNonStriker,
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
      'current_non_striker_id': openingNonStriker?.id,
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
      
    final dbBallData = {
      'id': ballId,
      'match_id': matchId,
      'innings_id': ballData['innings_id'],
      'over_number': ballData['over_number'],
      'ball_number': ballData['ball_number'],
      'bowler_id': ball.bowlerId,
      'batter_id': ball.batsmanId,
      'runs_scored': ball.batRuns,
      'extras_type': ball.extraType.name,
      'extras_runs': ball.extraRuns,
      'wicket_type': ball.wicketType?.name,
      'player_out_id': ball.dismissedPlayerId,
      'fielder_id': ball.fielderId,
      'is_legal_ball': ball.extraType != ExtraType.wide && ball.extraType != ExtraType.noball,
      'is_boundary': ball.batRuns >= 4,
      'ball_time': ball.timestamp.toIso8601String(),
    };

    final updateData = <String, dynamic>{
      'runs': snap.runs,
      'wickets': snap.wickets,
      'legal_balls': snap.legalBalls,
      'current_bowler_id': ball.bowlerId,
      'is_complete': complete != null,
    };
    if (snap.strikerId != null) {
      updateData['current_striker_id'] = snap.strikerId;
    }
    if (snap.nonStrikerId != null) {
      updateData['current_non_striker_id'] = snap.nonStrikerId;
    }

    await Future.wait([
      _supabase.from('ball_events').insert(dbBallData),
      _supabase.from('innings').update(updateData).eq('id', _innId(matchId, inningsNumber))
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
    try {
      // 1. Fetch match record
      final matchRes = await _supabase.from('matches').select().eq('id', matchId).maybeSingle();
      if (matchRes == null) return;
      final match = Match.fromJson(matchRes);

      // 2. Fetch both innings
      final inn1Res = await _supabase.from('innings').select().eq('id', _innId(matchId, 1)).maybeSingle();
      final inn2Res = await _supabase.from('innings').select().eq('id', _innId(matchId, 2)).maybeSingle();

      final inn1 = inn1Res != null ? Innings.fromJson(inn1Res) : null;
      final inn2 = inn2Res != null ? Innings.fromJson(inn2Res) : null;

      // 3. Fetch all balls for MoM calculation & score validation
      final balls1 = await loadAllBalls(tournamentId, matchId, 1);
      final balls2 = await loadAllBalls(tournamentId, matchId, 2);
      final allBalls = [...balls1, ...balls2];

      // 4. Calculate Winner & Result Text
      String? winnerTeamId;
      String resultText = 'Match Completed';
      bool isTie = false;

      final isCounty = match.liveScore?['isCounty'] == true || match.liveScore?['matchType'] == 'county';

      if (isCounty && inn1 != null) {
        final target = inn1.targetRuns ?? 0;
        final runs = inn1.runs;
        if (target > 0) {
          if (runs >= target) {
            winnerTeamId = inn1.battingTeamId;
            final winnerName = match.teamNameById(winnerTeamId);
            resultText = '$winnerName won the duel';
          } else {
            winnerTeamId = inn1.bowlingTeamId;
            final winnerName = match.teamNameById(winnerTeamId);
            resultText = '$winnerName won the duel';
          }
        } else {
          resultText = '${match.teamA} vs ${match.teamB} completed';
        }
      } else if (inn1 != null && inn2 != null) {
        final r1 = inn1.runs;
        final r2 = inn2.runs;
        final w2 = inn2.wickets;

        if (r2 > r1) {
          winnerTeamId = inn2.battingTeamId;
          final winnerName = match.teamNameById(winnerTeamId);
          final remWickets = (playersPerSide - 1 - w2).clamp(1, playersPerSide - 1);
          resultText = '$winnerName won by $remWickets ${remWickets == 1 ? 'wicket' : 'wickets'}';
        } else if (r1 > r2) {
          winnerTeamId = inn1.battingTeamId;
          final winnerName = match.teamNameById(winnerTeamId);
          final runMargin = r1 - r2;
          resultText = '$winnerName won by $runMargin ${runMargin == 1 ? 'run' : 'runs'}';
        } else {
          isTie = true;
          resultText = 'Match Tied';
        }
      } else if (inn1 != null && inn2 == null) {
        winnerTeamId = inn1.battingTeamId;
        resultText = '${match.teamNameById(winnerTeamId)} scored ${inn1.runs}/${inn1.wickets}';
      }

      // 5. Automatic Man of the Match Calculation
      final Map<String, _PlayerImpact> impactMap = {};

      for (final b in allBalls) {
        // Batter impact
        if (b.batsmanId.isNotEmpty) {
          final impact = impactMap.putIfAbsent(b.batsmanId, () => _PlayerImpact(id: b.batsmanId, name: b.batsmanName));
          if (b.creditsBatsmanRuns) {
            impact.runs += b.batRuns;
            if (b.batRuns == 4) impact.fours++;
            if (b.batRuns == 6) impact.sixes++;
          }
          if (b.countsAsBallFaced) impact.balls++;
        }

        // Bowler impact
        if (b.bowlerId.isNotEmpty) {
          final impact = impactMap.putIfAbsent(b.bowlerId, () => _PlayerImpact(id: b.bowlerId, name: b.bowlerName));
          impact.runsConceded += b.bowlerRunsConceded;
          if (b.isLegalDelivery) impact.bowlingBalls++;
          if (b.isWicket && (b.wicketType == null || b.wicketType!.creditedToBowler)) {
            impact.wickets++;
          }
        }

        // Fielder impact
        if (b.fielderId != null && b.fielderId!.isNotEmpty) {
          final impact = impactMap.putIfAbsent(b.fielderId!, () => _PlayerImpact(id: b.fielderId!, name: b.fielderName ?? 'Fielder'));
          impact.catches++;
        }
      }

      String? bestPlayerId;
      String? bestPlayerName;
      double highestPoints = -1.0;

      for (final impact in impactMap.values) {
        final pts = impact.totalPoints;
        if (pts > highestPoints) {
          highestPoints = pts;
          bestPlayerId = impact.id;
          bestPlayerName = impact.name;
        }
      }

      // 6. Update matches in Supabase
      final updateData = <String, dynamic>{
        'status': MatchStatus.completed.name,
        'winner_team_id': winnerTeamId,
        'result_text': resultText,
        'is_tie': isTie,
        'completed_at': DateTime.now().toIso8601String(),
      };

      if (bestPlayerId != null && bestPlayerName != null && (match.manOfTheMatchId == null || match.manOfTheMatchId!.isEmpty)) {
        updateData['man_of_the_match_id'] = bestPlayerId;
        updateData['man_of_the_match_name'] = bestPlayerName;
      }

      await _supabase.from('matches').update(updateData).eq('id', matchId);
    } catch (e) {
      // ignore
    }
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

class _PlayerImpact {
  final String id;
  final String name;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  int wickets = 0;
  int runsConceded = 0;
  int bowlingBalls = 0;
  int catches = 0;

  _PlayerImpact({required this.id, required this.name});

  double get totalPoints {
    double pts = 0.0;
    // Batting points: 1 pt per run, +1 per 4, +2 per 6, milestone bonuses
    pts += runs * 1.0;
    pts += fours * 1.0;
    pts += sixes * 2.0;
    if (runs >= 100) {
      pts += 16.0;
    } else if (runs >= 50) {
      pts += 8.0;
    } else if (runs >= 30) {
      pts += 4.0;
    }

    // Bowling points: 25 pts per wicket, milestone bonuses
    pts += wickets * 25.0;
    if (wickets >= 5) {
      pts += 16.0;
    } else if (wickets >= 3) {
      pts += 8.0;
    }

    // Economy bonus for bowlers who bowled at least 1 over (6 legal balls)
    if (bowlingBalls >= 6) {
      final econ = (runsConceded / bowlingBalls) * 6.0;
      if (econ < 5.0) {
        pts += 6.0;
      } else if (econ < 7.0) {
        pts += 3.0;
      }
    }

    // Fielding points: 8 pts per catch/stumping/run-out
    pts += catches * 8.0;

    return pts;
  }
}
