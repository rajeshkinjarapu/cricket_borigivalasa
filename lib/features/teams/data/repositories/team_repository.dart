import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/team.dart';

class TeamRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Team>> getAll() async {
    try {
      final data = await _supabase.from('teams').select();
      final list = (data as List).map((json) => Team.fromJson(json as Map<String, dynamic>)).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (_) {
      return [];
    }
  }

  Stream<List<Team>> watchAll() {
    return _supabase.from('teams').stream(primaryKey: ['id']).map(
          (data) {
            final list = data
                .map((json) => Team.fromJson(json))
                .toList();
            list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return list;
          },
        );
  }

  Stream<List<Team>> watchByTournament(String tournamentId) {
    return _supabase
        .from('teams')
        .stream(primaryKey: ['id'])
        // Supabase Postgres array contains operator is usually 'cs' or filtering on client side.
        // For streams, complex filtering on arrays might require a view or client-side filter.
        // We will filter client side to be safe with stream()
        .map((data) => data
            .where((json) {
              final tIds = json['tournament_ids'] as List<dynamic>? ?? [];
              return tIds.contains(tournamentId);
            })
            .map((json) => Team.fromJson(json))
            .toList());
  }

  Stream<Team?> watchById(String id) {
    return _supabase
        .from('teams')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isNotEmpty ? Team.fromJson(data.first) : null);
  }

  Future<String> create(Team team) async {
    final id = team.id.isEmpty ? const Uuid().v4() : team.id;
    final data = team.toJson();
    data['id'] = id;
    data['created_at'] = DateTime.now().toIso8601String();
    data.remove('captain_name'); // Not a column in Supabase teams table
    
    await _supabase.from('teams').insert(data);
    return id;
  }

  Future<void> update(Team team) async {
    final data = team.toJson();
    data.remove('id');
    data.remove('captain_name'); // Not a column in Supabase teams table
    await _supabase.from('teams').update(data).eq('id', team.id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('teams').delete().eq('id', id);
  }
}
