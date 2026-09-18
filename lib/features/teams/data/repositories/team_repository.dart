import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';

class TeamRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Team>> watchAll() {
    return _db.collection('teams').orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Team.fromJson({...doc.data(), 'id': doc.id})).toList(),
        );
  }

  Stream<List<Team>> watchByTournament(String tournamentId) {
    return _db
        .collection('teams')
        .where('tournamentIds', arrayContains: tournamentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Team.fromJson({...doc.data(), 'id': doc.id})).toList());
  }

  Stream<Team?> watchById(String id) {
    return _db.collection('teams').doc(id).snapshots().map((doc) => doc.exists ? Team.fromJson({...doc.data()!, 'id': doc.id}) : null);
  }

  Future<String> create(Team team) async {
    final doc = await _db.collection('teams').add(team.toJson()..remove('id'));
    return doc.id;
  }

  Future<void> update(Team team) async {
    await _db.collection('teams').doc(team.id).update(team.toJson()..remove('id'));
  }

  Future<void> delete(String id) async {
    await _db.collection('teams').doc(id).delete();
  }
}
