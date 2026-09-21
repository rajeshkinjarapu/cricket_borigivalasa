import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../models/tournament.dart';

class TournamentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Tournament>> getActiveTournaments() {
    return _supabase
        .from('tournaments')
        .stream(primaryKey: ['id'])
        .neq('status', TournamentStatus.completed.name)
        .map((data) => data
            .map((json) => Tournament.fromJson(json))
            .toList());
  }

  Stream<List<Tournament>> getAllTournaments() => watchAll();

  Stream<List<Tournament>> watchAll() {
    return _supabase
        .from('tournaments')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((json) => Tournament.fromJson(json))
            .toList());
  }

  Stream<Tournament?> watchById(String id) {
    return _supabase
        .from('tournaments')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isNotEmpty ? Tournament.fromJson(data.first) : null);
  }

  Future<String> create(Tournament t) async {
    final id = t.id.isEmpty ? const Uuid().v4() : t.id;
    final map = t.toJson();
    map['id'] = id;
    
    await _supabase.from('tournaments').insert(map);
    return id;
  }

  Future<void> update(Tournament t) async {
    final map = t.toJson();
    map.remove('id'); // ID is primary key, don't update it
    await _supabase.from('tournaments').update(map).eq('id', t.id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('tournaments').delete().eq('id', id);
  }
}
