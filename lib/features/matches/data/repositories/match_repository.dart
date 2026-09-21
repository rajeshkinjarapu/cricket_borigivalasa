import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../models/match.dart';

class MatchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Match>> watchAll(String tournamentId) {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .map((data) {
      final list = data.map((json) => Match.fromJson(json)).toList();
      list.sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return list;
    });
  }

  Stream<Match?> watchById(String tournamentId, String matchId) {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((data) => data.isNotEmpty ? Match.fromJson(data.first) : null);
  }

  Future<String> create(String tournamentId, Match match) async {
    final id = match.id.isEmpty ? const Uuid().v4() : match.id;
    final json = match.toJson();
    json['id'] = id;
    json['tournament_id'] = tournamentId;
    json['created_at'] = DateTime.now().toIso8601String();
    
    await _supabase.from('matches').insert(json);
    return id;
  }

  Future<void> update(String tournamentId, Match match) async {
    final json = match.toJson();
    json.remove('id');
    await _supabase.from('matches').update(json).eq('id', match.id);
  }

  Future<void> updatePartial({
    required String tournamentId,
    required String matchId,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('matches').update(data).eq('id', matchId);
  }

  Future<void> delete(String tournamentId, String matchId) async {
    await _supabase.from('matches').delete().eq('id', matchId);
  }

  Future<void> setToss({
    required String tournamentId,
    required String matchId,
    required String tossWinnerTeamId,
    required TossDecision tossDecision,
  }) async {
    await _supabase.from('matches').update({
      'toss_winner_id': tossWinnerTeamId,
      'toss_decision': tossDecision.name,
      // Supabase updated_at trigger usually handles time, but we can set it
    }).eq('id', matchId);
  }

  Future<void> completeMatch({
    required String tournamentId,
    required String matchId,
    required String? winnerTeamId,
    required String resultText,
    bool isTie = false,
  }) async {
    await _supabase.from('matches').update({
      'status': MatchStatus.completed.name,
      'winner_team_id': winnerTeamId,
      'result_text': resultText,
      'is_tie': isTie,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', matchId);
  }

  Future<void> revertToScheduled({
    required String tournamentId,
    required String matchId,
  }) async {
    await _supabase.from('matches').update({
      'status': MatchStatus.scheduled.name,
      'live_score': null,
      'winner_team_id': null,
      'result_text': null,
      'is_tie': false,
      'started_at': null,
      'completed_at': null,
    }).eq('id', matchId);
  }

  Stream<List<Match>> getLiveMatches() {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((json) => Match.fromJson(json))
            .where((m) => m.status == MatchStatus.live || (m.status != MatchStatus.completed && m.liveScore != null))
            .toList());
  }

  Stream<List<Match>> getUpcomingMatches() {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('status', MatchStatus.scheduled.name)
        .map((data) {
      final list = data.map((json) => Match.fromJson(json)).toList();
      list.sort((a, b) => a.matchDate.compareTo(b.matchDate));
      return list.take(15).toList();
    });
  }

  Stream<List<Match>> getAllMatches() {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .map((data) {
      final list = data.map((json) => Match.fromJson(json)).toList();
      list.sort((a, b) => b.matchDate.compareTo(a.matchDate));
      return list;
    });
  }
}
