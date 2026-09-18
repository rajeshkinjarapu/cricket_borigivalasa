import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';

class PlayerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Player>> watchByTeam(String teamId) {
    return _db
        .collection('players')
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Player.fromJson({...doc.data(), 'id': doc.id})).toList());
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
}
