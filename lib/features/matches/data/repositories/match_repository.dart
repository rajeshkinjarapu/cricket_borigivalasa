import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../models/match.dart';

class MatchRepository {
  MatchRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _matchesRef(String tournamentId) {
    return _db
        .collection(AppConstants.tournamentsCollection)
        .doc(tournamentId)
        .collection(AppConstants.matchesCollection);
  }

  Match _parseDoc(DocumentSnapshot<Map<String, dynamic>> doc, [String? fallbackTournamentId]) {
    final data = doc.data() ?? {};
    String tId = data['tournamentId'] as String? ?? fallbackTournamentId ?? '';
    if (tId.isEmpty) {
      final segments = doc.reference.path.split('/');
      if (segments.length >= 2 && segments[0] == AppConstants.tournamentsCollection) {
        tId = segments[1];
      }
    }
    return Match.fromJson({...data, 'id': doc.id, 'tournamentId': tId});
  }

  Stream<List<Match>> watchAll(String tournamentId) {
    return _matchesRef(tournamentId)
        .orderBy('matchDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _parseDoc(d, tournamentId)).toList());
  }

  Stream<Match?> watchById(String tournamentId, String matchId) {
    return _matchesRef(tournamentId).doc(matchId).snapshots().map((d) {
      if (!d.exists || d.data() == null) return null;
      return _parseDoc(d, tournamentId);
    });
  }

  Future<String> create(String tournamentId, Match match) async {
    final json = match.toJson()
      ..remove('id')
      ..['tournamentId'] = tournamentId
      ..['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _matchesRef(tournamentId).add(json);
    return doc.id;
  }

  Future<void> update(String tournamentId, Match match) async {
    final json = match.toJson()..remove('id');
    await _matchesRef(tournamentId).doc(match.id).update(json);
  }

  Future<void> updatePartial({
    required String tournamentId,
    required String matchId,
    required Map<String, dynamic> data,
  }) async {
    await _matchesRef(tournamentId).doc(matchId).update(data);
  }

  Future<void> delete(String tournamentId, String matchId) async {
    await _matchesRef(tournamentId).doc(matchId).delete();
  }

  Future<void> setToss({
    required String tournamentId,
    required String matchId,
    required String tossWinnerTeamId,
    required TossDecision tossDecision,
  }) async {
    await _matchesRef(tournamentId).doc(matchId).update({
      'tossWinnerId': tossWinnerTeamId,
      'tossWinnerTeamId': tossWinnerTeamId,
      'tossDecision': tossDecision.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeMatch({
    required String tournamentId,
    required String matchId,
    required String? winnerTeamId,
    required String resultText,
    bool isTie = false,
  }) async {
    await _matchesRef(tournamentId).doc(matchId).update({
      'status': MatchStatus.completed.name,
      'winnerTeamId': winnerTeamId,
      'resultText': resultText,
      'isTie': isTie,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> revertToScheduled({
    required String tournamentId,
    required String matchId,
  }) async {
    await _matchesRef(tournamentId).doc(matchId).update({
      'status': MatchStatus.scheduled.name,
      'liveScore': FieldValue.delete(),
      'winnerTeamId': FieldValue.delete(),
      'resultText': FieldValue.delete(),
      'isTie': false,
      'startedAt': FieldValue.delete(),
      'completedAt': FieldValue.delete(),
    });
  }

  Stream<List<Match>> getLiveMatches() {
    return _db
        .collectionGroup(AppConstants.matchesCollection)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _parseDoc(d))
            .where((m) => m.status == MatchStatus.live || (m.status != MatchStatus.completed && m.liveScore != null))
            .toList());
  }

  Stream<List<Match>> getUpcomingMatches() {
    return _db
        .collectionGroup(AppConstants.matchesCollection)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => _parseDoc(d))
          .where((m) => m.status == MatchStatus.scheduled)
          .toList();
      list.sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return list.take(15).toList();
    });
  }

  Stream<List<Match>> getAllMatches() {
    return _db
        .collectionGroup(AppConstants.matchesCollection)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => _parseDoc(d)).toList();
      list.sort((a, b) => b.matchDate.compareTo(a.matchDate));
      return list;
    });
  }
}
