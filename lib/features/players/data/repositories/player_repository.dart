import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';

class PlayerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Player>> watchAll() {
    return _supabase.from('players').stream(primaryKey: ['id']).map((data) {
      final list = data.map((json) => Player.fromJson(json)).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<List<Player>> watchByTeam(String teamId) {
    return _supabase.from('players').stream(primaryKey: ['id']).map((data) {
      final list = data
          .map((json) => Player.fromJson(json))
          .where((p) => p.teamId == teamId || p.teamIds.contains(teamId))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<Player?> watchById(String id) {
    return _supabase
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isNotEmpty ? Player.fromJson(data.first) : null);
  }

  Future<String> create(Player player) async {
    final id = player.id.isEmpty ? const Uuid().v4() : player.id;
    final map = player.toJson();
    map['id'] = id;
    
    await _supabase.from('players').insert(map);
    return id;
  }

  Future<void> update(Player player) async {
    final map = player.toJson();
    map.remove('id');
    await _supabase.from('players').update(map).eq('id', player.id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('players').delete().eq('id', id);
  }

  Future<void> addPlayerToTeam(String playerId, String teamId) async {
    final res = await _supabase.from('players').select('team_id, team_ids').eq('id', playerId).maybeSingle();
    if (res == null) return;
    
    final currentTeamId = res['team_id'] as String? ?? '';
    final rawList = (res['team_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final currentTeamIds = {...rawList};
    if (currentTeamId.isNotEmpty) currentTeamIds.add(currentTeamId);
    currentTeamIds.add(teamId);
    
    await _supabase.from('players').update({
      'team_id': currentTeamId.isEmpty ? teamId : currentTeamId,
      'team_ids': currentTeamIds.toList(),
    }).eq('id', playerId);
  }

  Future<void> removePlayerFromTeam(String playerId, String teamId) async {
    final res = await _supabase.from('players').select('team_id, team_ids').eq('id', playerId).maybeSingle();
    if (res == null) return;
    
    final currentTeamId = res['team_id'] as String? ?? '';
    final rawList = (res['team_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final currentTeamIds = {...rawList};
    if (currentTeamId.isNotEmpty) currentTeamIds.add(currentTeamId);
    currentTeamIds.remove(teamId);
    
    final newPrimary = currentTeamIds.isNotEmpty ? currentTeamIds.first : '';
    await _supabase.from('players').update({
      'team_id': currentTeamId == teamId ? newPrimary : currentTeamId,
      'team_ids': currentTeamIds.toList(),
    }).eq('id', playerId);
  }
}
