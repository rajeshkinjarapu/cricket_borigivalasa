import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';

class PlayerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Player>> watchAll() {
    return _db.collection('players').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Player.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<List<Player>> watchByTeam(String teamId) {
    return _db.collection('players').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Player.fromJson({...doc.data(), 'id': doc.id}))
          .where((p) => p.teamId == teamId || p.teamIds.contains(teamId))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Stream<Player?> watchById(String id) {
    return _db.collection('players').doc(id).snapshots().map((doc) => doc.exists ? Player.fromJson({...doc.data()!, 'id': doc.id}) : null);
  }

  Future<String> create(Player player) async {
    final doc = await _db.collection('players').add(player.toJson()..remove('id'));
    return doc.id;
  }

  Future<void> update(Player player) async {
    await _db.collection('players').doc(player.id).update(player.toJson()..remove('id'));
  }

  Future<void> delete(String id) async {
    await _db.collection('players').doc(id).delete();
  }

  Future<void> addPlayerToTeam(String playerId, String teamId) async {
    final docRef = _db.collection('players').doc(playerId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final currentTeamId = data['teamId'] as String? ?? '';
    final rawList = (data['teamIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final currentTeamIds = {...rawList};
    if (currentTeamId.isNotEmpty) currentTeamIds.add(currentTeamId);
    currentTeamIds.add(teamId);
    await docRef.update({
      'teamId': currentTeamId.isEmpty ? teamId : currentTeamId,
      'teamIds': currentTeamIds.toList(),
    });
  }

  Future<void> removePlayerFromTeam(String playerId, String teamId) async {
    final docRef = _db.collection('players').doc(playerId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final currentTeamId = data['teamId'] as String? ?? '';
    final rawList = (data['teamIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final currentTeamIds = {...rawList};
    if (currentTeamId.isNotEmpty) currentTeamIds.add(currentTeamId);
    currentTeamIds.remove(teamId);
    final newPrimary = currentTeamIds.isNotEmpty ? currentTeamIds.first : '';
    await docRef.update({
      'teamId': currentTeamId == teamId ? newPrimary : currentTeamId,
      'teamIds': currentTeamIds.toList(),
    });
  }
}
