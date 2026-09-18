import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../players/data/models/player.dart';
import '../../../teams/data/models/team.dart';
import '../../domain/scoring_engine.dart';
import '../models/ball_event.dart';
import '../models/innings.dart';

class ScoringRepository {
  ScoringRepository({FirebaseFirestore? f}) : _db = f ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _matchRef(String t, String m) => _db
    .collection(AppConstants.tournamentsCollection).doc(t)
    .collection(AppConstants.matchesCollection).doc(m);
  DocumentReference<Map<String, dynamic>> _innRef(String t, String m, int n) =>
    _matchRef(t, m).collection(AppConstants.inningsCollection).doc(n.toString());
  CollectionReference<Map<String, dynamic>> _oversRef(String t, String m, int n) =>
    _innRef(t, m, n).collection(AppConstants.oversCollection);
  CollectionReference<Map<String, dynamic>> _batRef(String t, String m, int n) =>
    _innRef(t, m, n).collection(AppConstants.battingScorecardCollection);
  CollectionReference<Map<String, dynamic>> _bowlRef(String t, String m, int n) =>
    _innRef(t, m, n).collection(AppConstants.bowlingScorecardCollection);

  Stream<Innings?> watchInnings(String t, String m, int n) =>
    _innRef(t, m, n).snapshots().map((d) => !d.exists ? null
      : Innings.fromJson({...d.data()!, 'inningsNumber': n}));

  Stream<List<BattingScorecardRow>> watchBatting(String t, String m, int n) =>
    _batRef(t, m, n).snapshots().map((s) => s.docs
      .map((d) => BattingScorecardRow.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.battingOrder.compareTo(b.battingOrder)));

  Stream<List<BowlingScorecardRow>> watchBowling(String t, String m, int n) =>
    _bowlRef(t, m, n).snapshots().map((s) => s.docs
      .map((d) => BowlingScorecardRow.fromMap(d.id, d.data())).toList());

  Future<List<BallEvent>> loadAllBalls(String t, String m, int n) async {
    final snap = await _oversRef(t, m, n).orderBy('overNumber').get();
    final out = <BallEvent>[];
    for (final doc in snap.docs) {
      final raw = (doc.data()['balls'] as List?) ?? const [];
      for (final b in raw) {
        out.add(BallEvent.fromJson(Map<String, dynamic>.from(b as Map)));
      }
    }
    return out;
  }

  Future<void> initInnings({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Team battingTeam, required Team bowlingTeam,
      required Player openingStriker, required Player openingNonStriker,
      required Player openingBowler, int? targetRuns}) async {
    await _innRef(tournamentId, matchId, inningsNumber).set({
      'battingTeamId': battingTeam.id, 'battingTeamName': battingTeam.name,
      'battingTeamShort': battingTeam.shortName,
      'bowlingTeamId': bowlingTeam.id, 'bowlingTeamName': bowlingTeam.name,
      'bowlingTeamShort': bowlingTeam.shortName,
      'openingStrikerId': openingStriker.id,
      'openingStrikerName': openingStriker.name,
      'openingNonStrikerId': openingNonStriker.id,
      'openingNonStrikerName': openingNonStriker.name,
      'strikerId': openingStriker.id, 'strikerName': openingStriker.name,
      'nonStrikerId': openingNonStriker.id,
      'nonStrikerName': openingNonStriker.name,
      'currentBowlerId': openingBowler.id,
      'currentBowlerName': openingBowler.name,
      'runs': 0, 'wickets': 0, 'legalBalls': 0,
      'wides': 0, 'noballs': 0, 'byes': 0, 'legbyes': 0,
      'targetRuns': targetRuns, 'isComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp()});
    final b = _db.batch();
    b.set(_batRef(tournamentId, matchId, inningsNumber).doc(openingStriker.id), {
      'playerName': openingStriker.name, 'battingOrder': 1, 'runs': 0,
      'balls': 0, 'fours': 0, 'sixes': 0, 'isOut': false,
      'isStriker': true, 'isNonStriker': false});
    b.set(_batRef(tournamentId, matchId, inningsNumber).doc(openingNonStriker.id), {
      'playerName': openingNonStriker.name, 'battingOrder': 2, 'runs': 0,
      'balls': 0, 'fours': 0, 'sixes': 0, 'isOut': false,
      'isStriker': false, 'isNonStriker': true});
    b.set(_bowlRef(tournamentId, matchId, inningsNumber).doc(openingBowler.id), {
      'playerName': openingBowler.name, 'balls': 0, 'runs': 0, 'wickets': 0,
      'maidens': 0, 'wides': 0, 'noballs': 0});
    await b.commit();
  }

  Future<void> recordBall({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Innings innings, required BallEvent ball,
      required int maxOvers, required int playersPerSide}) async {
    final oversSnap = await _oversRef(tournamentId, matchId, inningsNumber)
      .orderBy('overNumber').get();
    final allBalls = <BallEvent>[];
    for (final doc in oversSnap.docs) {
      final raw = (doc.data()['balls'] as List?) ?? const [];
      for (final b in raw) {
        allBalls.add(BallEvent.fromJson(Map<String, dynamic>.from(b as Map)));
      }
    }
    allBalls.add(ball);
    final snap = ScoringEngine.reduce(
      openingStrikerId: innings.openingStrikerId,
      openingStrikerName: innings.openingStrikerName,
      openingNonStrikerId: innings.openingNonStrikerId,
      openingNonStrikerName: innings.openingNonStrikerName, balls: allBalls);
    final legalBefore = allBalls.take(allBalls.length - 1)
      .where((b) => b.isLegalDelivery).length;
    final overNumber = (legalBefore ~/ 6) + 1;
    final complete = ScoringEngine.checkInningsComplete(snap: snap,
      maxOvers: maxOvers, playersPerSide: playersPerSide,
      targetRuns: innings.targetRuns);

    final b = _db.batch();
    b.set(_oversRef(tournamentId, matchId, inningsNumber).doc(overNumber.toString()),
      {'overNumber': overNumber, 'bowlerId': ball.bowlerId,
       'bowlerName': ball.bowlerName,
       'balls': FieldValue.arrayUnion([ball.toJson()])},
      SetOptions(merge: true));
    b.update(_innRef(tournamentId, matchId, inningsNumber), {
      'runs': snap.runs, 'wickets': snap.wickets, 'legalBalls': snap.legalBalls,
      'wides': snap.wides, 'noballs': snap.noballs, 'byes': snap.byes,
      'legbyes': snap.legbyes, 'strikerId': snap.strikerId,
      'strikerName': snap.strikerName, 'nonStrikerId': snap.nonStrikerId,
      'nonStrikerName': snap.nonStrikerName,
      'currentBowlerId': ball.bowlerId, 'currentBowlerName': ball.bowlerName,
      'isComplete': complete != null,
      if (complete != null) 'completionReason': complete,
      'updatedAt': FieldValue.serverTimestamp()});
    for (final e in snap.batting.entries) {
      b.set(_batRef(tournamentId, matchId, inningsNumber).doc(e.key),
        e.value.toJson()..remove('playerId'), SetOptions(merge: false));
    }
    final maidens = _computeMaidens(allBalls);
    for (final e in snap.bowling.entries) {
      final bw = e.value.copyWith(maidens: maidens[e.key] ?? 0);
      b.set(_bowlRef(tournamentId, matchId, inningsNumber).doc(e.key),
        bw.toJson()..remove('playerId'), SetOptions(merge: false));
    }
    await b.commit();
  }

  Future<void> undoLastBall({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Innings innings, required int maxOvers,
      required int playersPerSide}) async {
    final snap = await _oversRef(tournamentId, matchId, inningsNumber)
      .orderBy('overNumber', descending: true).get();
    if (snap.docs.isEmpty) return;
    DocumentSnapshot<Map<String, dynamic>>? target;
    for (final doc in snap.docs) {
      final raw = (doc.data()['balls'] as List?) ?? const [];
      if (raw.isNotEmpty) { target = doc; break; }
    }
    if (target == null) return;
    final rawBalls = List<Map<String, dynamic>>.from(target.data()!['balls'] as List);
    rawBalls.removeLast();
    final allBalls = <BallEvent>[];
    for (final doc in snap.docs.reversed) {
      if (doc.id == target.id) {
        for (final x in rawBalls) allBalls.add(
          BallEvent.fromJson(Map<String, dynamic>.from(x)));
      } else {
        final raw = (doc.data()['balls'] as List?) ?? const [];
        for (final x in raw) allBalls.add(
          BallEvent.fromJson(Map<String, dynamic>.from(x as Map)));
      }
    }
    final s = ScoringEngine.reduce(
      openingStrikerId: innings.openingStrikerId,
      openingStrikerName: innings.openingStrikerName,
      openingNonStrikerId: innings.openingNonStrikerId,
      openingNonStrikerName: innings.openingNonStrikerName, balls: allBalls);
    final b = _db.batch();
    final targetRef = _oversRef(tournamentId, matchId, inningsNumber).doc(target.id);
    if (rawBalls.isEmpty) b.delete(targetRef);
    else b.update(targetRef, {'balls': rawBalls});

    final batIds = s.batting.keys.toSet();
    final bowlIds = s.bowling.keys.toSet();
    final eb = await _batRef(tournamentId, matchId, inningsNumber).get();
    for (final d in eb.docs) if (!batIds.contains(d.id)) b.delete(d.reference);
    final ebow = await _bowlRef(tournamentId, matchId, inningsNumber).get();
    for (final d in ebow.docs) if (!bowlIds.contains(d.id)) b.delete(d.reference);

    for (final e in s.batting.entries) {
      b.set(_batRef(tournamentId, matchId, inningsNumber).doc(e.key),
        e.value.toJson()..remove('playerId'), SetOptions(merge: false));
    }
    final maidens = _computeMaidens(allBalls);
    for (final e in s.bowling.entries) {
      final bw = e.value.copyWith(maidens: maidens[e.key] ?? 0);
      b.set(_bowlRef(tournamentId, matchId, inningsNumber).doc(e.key),
        bw.toJson()..remove('playerId'), SetOptions(merge: false));
    }
    final prev = allBalls.isNotEmpty ? allBalls.last : null;
    b.update(_innRef(tournamentId, matchId, inningsNumber), {
      'runs': s.runs, 'wickets': s.wickets, 'legalBalls': s.legalBalls,
      'wides': s.wides, 'noballs': s.noballs, 'byes': s.byes,
      'legbyes': s.legbyes, 'strikerId': s.strikerId,
      'strikerName': s.strikerName, 'nonStrikerId': s.nonStrikerId,
      'nonStrikerName': s.nonStrikerName,
      'currentBowlerId': prev?.bowlerId ?? innings.currentBowlerId,
      'currentBowlerName': prev?.bowlerName ?? innings.currentBowlerName,
      'isComplete': false, 'completionReason': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp()});
    await b.commit();
  }

  Future<void> setCurrentBowler({required String tournamentId,
      required String matchId, required int inningsNumber,
      required Player bowler}) async {
    await _innRef(tournamentId, matchId, inningsNumber).update({
      'currentBowlerId': bowler.id, 'currentBowlerName': bowler.name,
      'updatedAt': FieldValue.serverTimestamp()});
    final ref = _bowlRef(tournamentId, matchId, inningsNumber).doc(bowler.id);
    if (!(await ref.get()).exists) {
      await ref.set({'playerName': bowler.name, 'balls': 0, 'runs': 0,
        'wickets': 0, 'maidens': 0, 'wides': 0, 'noballs': 0});
    }
  }

  Map<String, int> _computeMaidens(List<BallEvent> balls) {
    final overs = <String, List<BallEvent>>{};
    int legal = 0;
    for (final b in balls) {
      final overNo = (legal ~/ 6) + 1;
      overs.putIfAbsent('${b.bowlerId}#$overNo', () => []).add(b);
      if (b.isLegalDelivery) legal++;
    }
    final result = <String, int>{};
    for (final e in overs.entries) {
      final list = e.value;
      if (list.where((b) => b.isLegalDelivery).length < 6) continue;
      final rc = list.fold<int>(0, (s, b) => s + b.bowlerRunsConceded);
      final w = list.any((b) => b.isWicket);
      if (rc == 0 && !w) {
        final id = e.key.split('#').first;
        result[id] = (result[id] ?? 0) + 1;
      }
    }
    return result;
  }
}

class BattingScorecardRow {
  final String playerId, playerName;
  final int battingOrder, runs, balls, fours, sixes;
  final bool isOut;
  final String? dismissalText;
  BattingScorecardRow.fromMap(this.playerId, Map<String, dynamic> m)
    : playerName = (m['playerName'] as String?) ?? 'Player',
      battingOrder = (m['battingOrder'] as num?)?.toInt() ?? 99,
      runs = (m['runs'] as num?)?.toInt() ?? 0,
      balls = (m['balls'] as num?)?.toInt() ?? 0,
      fours = (m['fours'] as num?)?.toInt() ?? 0,
      sixes = (m['sixes'] as num?)?.toInt() ?? 0,
      isOut = (m['isOut'] as bool?) ?? false,
      dismissalText = m['dismissalText'] as String?;
}

class BowlingScorecardRow {
  final String playerId, playerName;
  final int balls, runs, wickets, maidens, wides, noballs;
  BowlingScorecardRow.fromMap(this.playerId, Map<String, dynamic> m)
    : playerName = (m['playerName'] as String?) ?? 'Player',
      balls = (m['balls'] as num?)?.toInt() ?? 0,
      runs = (m['runs'] as num?)?.toInt() ?? 0,
      wickets = (m['wickets'] as num?)?.toInt() ?? 0,
      maidens = (m['maidens'] as num?)?.toInt() ?? 0,
      wides = (m['wides'] as num?)?.toInt() ?? 0,
      noballs = (m['noballs'] as num?)?.toInt() ?? 0;
}
