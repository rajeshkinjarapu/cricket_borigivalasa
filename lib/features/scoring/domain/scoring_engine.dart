import '../../../core/constants/cricket_enums.dart';
import '../data/models/ball_event.dart';
import '../data/models/batting_scorecard.dart';
import '../data/models/bowling_scorecard.dart';

class FallOfWicket {
  final String playerId;
  final String playerName;
  final int score;
  final String oversText;
  const FallOfWicket({required this.playerId, required this.playerName,
    required this.score, required this.oversText});
}

class InningsSnapshot {
  final int runs, wickets, legalBalls, wides, noballs, byes, legbyes;
  final String? strikerId, strikerName, nonStrikerId, nonStrikerName;
  final String? currentBowlerId, currentBowlerName;
  final Map<String, BattingScorecard> batting;
  final Map<String, BowlingScorecard> bowling;
  final List<FallOfWicket> fallOfWickets;

  const InningsSnapshot({
    required this.runs, required this.wickets, required this.legalBalls,
    required this.wides, required this.noballs, required this.byes,
    required this.legbyes, required this.strikerId, required this.strikerName,
    required this.nonStrikerId, required this.nonStrikerName,
    required this.currentBowlerId, required this.currentBowlerName,
    required this.batting, required this.bowling,
    required this.fallOfWickets});
}

class ScoringEngine {
  ScoringEngine._();

  static InningsSnapshot reduce({
    required String openingStrikerId,
    required String openingStrikerName,
    required String? openingNonStrikerId,
    required String? openingNonStrikerName,
    required List<BallEvent> balls,
  }) {
    String? strikerId = openingStrikerId;
    String? strikerName = openingStrikerName;
    var nonStrikerId = openingNonStrikerId;
    var nonStrikerName = openingNonStrikerName;
    String? currentBowlerId, currentBowlerName;
    int runs = 0, wickets = 0, legalBalls = 0;
    int wides = 0, noballs = 0, byes = 0, legbyes = 0;
    final batting = <String, BattingScorecard>{};
    final bowling = <String, BowlingScorecard>{};
    final fow = <FallOfWicket>[];

    batting[openingStrikerId] = BattingScorecard(
      playerId: openingStrikerId, playerName: openingStrikerName,
      battingOrder: 1);
    if (openingNonStrikerId != null && openingNonStrikerName != null) {
      batting[openingNonStrikerId] = BattingScorecard(
        playerId: openingNonStrikerId, playerName: openingNonStrikerName,
        battingOrder: 2);
    }

    for (final ball in balls) {
      currentBowlerId = ball.bowlerId;
      currentBowlerName = ball.bowlerName;
      batting.putIfAbsent(ball.batsmanId, () => BattingScorecard(
        playerId: ball.batsmanId, playerName: ball.batsmanName,
        battingOrder: batting.length + 1));

      runs += ball.totalDeliveryRuns;
      if (ball.isLegalDelivery) legalBalls++;
      switch (ball.extraType) {
        case ExtraType.wide: wides += 1 + ball.extraRuns; break;
        case ExtraType.noball: noballs += 1; break;
        case ExtraType.bye: byes += ball.extraRuns; break;
        case ExtraType.legbye: legbyes += ball.extraRuns; break;
        case ExtraType.none: break;
      }

      var updated = batting[ball.batsmanId]!;
      if (ball.countsAsBallFaced) updated = updated.copyWith(balls: updated.balls + 1);
      if (ball.creditsBatsmanRuns) {
        updated = updated.copyWith(runs: updated.runs + ball.batRuns);
        if (ball.batRuns == 4) updated = updated.copyWith(fours: updated.fours + 1);
        if (ball.batRuns == 6) updated = updated.copyWith(sixes: updated.sixes + 1);
      }
      batting[ball.batsmanId] = updated;

      bowling.putIfAbsent(ball.bowlerId, () => BowlingScorecard(
        playerId: ball.bowlerId, playerName: ball.bowlerName));
      final bowler = bowling[ball.bowlerId]!;
      bowling[ball.bowlerId] = bowler.copyWith(
        runs: bowler.runs + ball.bowlerRunsConceded,
        balls: bowler.balls + (ball.isLegalDelivery ? 1 : 0),
        wickets: bowler.wickets + (ball.isWicket &&
          ball.wicketType!.creditedToBowler ? 1 : 0),
        wides: bowler.wides + (ball.extraType == ExtraType.wide
          ? 1 + ball.extraRuns : 0),
        noballs: bowler.noballs + (ball.extraType == ExtraType.noball
          ? 1 : 0));

      if (ball.isWicket) {
        wickets++;
        final outId = ball.dismissedPlayerId;
        if (outId != null) {
          final outP = batting.putIfAbsent(outId, () => BattingScorecard(
            playerId: outId, playerName: ball.dismissedPlayerName ?? 'Unknown',
            battingOrder: batting.length + 1));
          batting[outId] = outP.copyWith(isOut: true,
            dismissalText: _dismissalText(ball));
          fow.add(FallOfWicket(playerId: outId, playerName: outP.playerName,
            score: runs, oversText: '${legalBalls ~/ 6}.${legalBalls % 6}'));
        }
        if (ball.newBatsmanId != null) {
          final newId = ball.newBatsmanId!;
          batting.putIfAbsent(newId, () => BattingScorecard(
            playerId: newId, playerName: ball.newBatsmanName ?? 'Unknown',
            battingOrder: batting.length + 1));
          if (outId == strikerId) {
            strikerId = newId; strikerName = ball.newBatsmanName ?? 'Unknown';
          } else if (outId == nonStrikerId) {
            nonStrikerId = newId;
            nonStrikerName = ball.newBatsmanName ?? 'Unknown';
          }
        }
      }

      if (ball.rotatesStrike) {
        final tId = strikerId, tName = strikerName;
        strikerId = nonStrikerId; strikerName = nonStrikerName;
        nonStrikerId = tId; nonStrikerName = tName;
      }
      if (ball.isLegalDelivery && legalBalls % 6 == 0) {
        final tId = strikerId, tName = strikerName;
        strikerId = nonStrikerId; strikerName = nonStrikerName;
        nonStrikerId = tId; nonStrikerName = tName;
      }
    }

    final finalBatting = <String, BattingScorecard>{};
    for (final e in batting.entries) {
      finalBatting[e.key] = e.value.copyWith(
        isStriker: e.key == strikerId, isNonStriker: e.key == nonStrikerId);
    }

    return InningsSnapshot(runs: runs, wickets: wickets, legalBalls: legalBalls,
      wides: wides, noballs: noballs, byes: byes, legbyes: legbyes,
      strikerId: strikerId, strikerName: strikerName,
      nonStrikerId: nonStrikerId, nonStrikerName: nonStrikerName,
      currentBowlerId: currentBowlerId, currentBowlerName: currentBowlerName,
      batting: finalBatting, bowling: bowling, fallOfWickets: fow);
  }

  static String _dismissalText(BallEvent ball) {
    final t = ball.wicketType;
    if (t == null) return 'Out';
    switch (t) {
      case WicketType.bowled: return 'b ${ball.bowlerName}';
      case WicketType.caught: return ball.fielderName != null
        ? 'c ${ball.fielderName} b ${ball.bowlerName}'
        : 'c & b ${ball.bowlerName}';
      case WicketType.lbw: return 'lbw b ${ball.bowlerName}';
      case WicketType.stumped: return ball.fielderName != null
        ? 'st ${ball.fielderName} b ${ball.bowlerName}'
        : 'st b ${ball.bowlerName}';
      case WicketType.runOut: return ball.fielderName != null
        ? 'run out (${ball.fielderName})' : 'run out';
      case WicketType.hitWicket: return 'hit wicket b ${ball.bowlerName}';
      case WicketType.retiredHurt: return 'retired hurt';
      case WicketType.obstructingField: return 'obstructing';
    }
  }

  static String? checkInningsComplete({
    required InningsSnapshot snap,
    required int maxOvers,
    required int playersPerSide,
    int? targetRuns,
  }) {
    if (targetRuns != null && snap.runs >= targetRuns) return 'Target achieved';
    if (snap.wickets >= playersPerSide - 1) return 'All out';
    if (snap.legalBalls >= maxOvers * 6) return 'Overs complete';
    return null;
  }
}
