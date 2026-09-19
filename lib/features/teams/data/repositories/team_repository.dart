import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';

class TeamRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Team>> watchAll() {
    return _db.collection('teams').snapshots().map(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => Team.fromJson({...doc.data(), 'id': doc.id}))
                .toList();
            list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return list;
          },
        );
  }

  Stream<List<Team>> watchByTournament(String tournamentId) {
    return _db
        .collection('teams')
        .where('tournamentIds', arrayContains: tournamentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<Team?> watchById(String id) {
    return _db
        .collection('teams')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Team.fromJson({...doc.data()!, 'id': doc.id}) : null);
  }

  Future<String> create(Team team) async {
    final data = team.toJson()..remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _db.collection('teams').add(data);
    return doc.id;
  }

  Future<void> update(Team team) async {
    final data = team.toJson()..remove('id');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('teams').doc(team.id).update(data);
  }

  Future<void> delete(String id) async {
    await _db.collection('teams').doc(id).delete();
  }
}
